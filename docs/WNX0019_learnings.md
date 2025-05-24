# WNX0019 Learnings - Integrated Heartbeat Architecture

**FINAL IMPLEMENTATION UPDATE**: Based on these learnings, we chose to integrate heartbeat functionality directly into the Client GenServer rather than creating a separate HeartbeatManager. This simpler approach achieved all the same benefits with less complexity.

## Problem Discovered During Exploration
During initial exploration, a separate HeartbeatManager GenServer was attempted but couldn't receive WebSocket messages because:

1. **Gun sends messages to the calling process** - When Gun receives WebSocket messages, it sends them to the process that called `gun:open/3`
2. **Client is just a struct** - Not a GenServer or process that can receive messages
3. **No message routing** - Nothing forwards Gun messages to separate processes

## Additional Critical Issue: Reconnection Coordination
Beyond message routing, we discovered that **reconnection coordination** also requires Client to be a GenServer:

1. **Connection Monitoring** - Someone needs to monitor the Gun process and detect drops
2. **Reconnection Orchestration** - After a drop, the Reconnection module creates a new Gun process
3. **Message Routing Re-establishment** - The new Gun process needs to know where to send messages
4. **State Continuity** - Separate heartbeat processes must seamlessly continue with new connections

Without a coordinating GenServer, there's no central process to manage this complex lifecycle.

## What We Tried
- Explored separate HeartbeatManager GenServer to handle heartbeats
- Added logging to track message flow
- Discovered messages were being sent but never received
- Found that Gun messages had nowhere to go

## Architecture Options for Fix
1. **Client as GenServer** - Make Client a GenServer that receives Gun messages and forwards to separate heartbeat process
2. **Message Router Process** - Create a dedicated process to route messages from Gun to appropriate handlers
3. **Separate process owns Gun** - Have heartbeat process directly receive Gun messages (violates separation of concerns)

## Recommended Solution: Client as GenServer

After careful analysis, the **Client as GenServer** approach is optimal because:

### Advantages
- **Natural message receiver** - Client GenServer can receive Gun messages directly
- **Integrated approach chosen** - Client handles heartbeat functionality directly for optimal performance
- **Simplified architecture** - No message routing overhead or process coordination complexity
- **Backward compatibility** - Public API can remain the same
- **Future extensibility** - Enables other message processing features
- **Aligns with simplicity** - Single, clear message flow path

### Architecture Flow
```
Gun Process → Client GenServer → HeartbeatManager (heartbeat messages)
                              → User Handlers (application messages)
                              → Error Handlers (connection events)

Reconnection Flow:
1. Client GenServer monitors Gun process
2. Gun process dies → Client detects via monitor
3. Client calls Reconnection.reconnect → gets new Gun process
4. Client re-establishes message routing to HeartbeatManager
5. HeartbeatManager continues seamlessly with new connection
```

### Implementation Strategy

#### Phase 1: Client GenServer Refactor
1. Convert Client to GenServer - Maintain public API compatibility
2. Add message routing - Route Gun messages to appropriate handlers
3. Integrate HeartbeatManager - Forward heartbeat messages for processing
4. Preserve simplicity - Keep the Client interface clean and focused

#### Phase 2: HeartbeatManager Integration
1. Connect to Client - HeartbeatManager receives messages via Client routing
2. Test with real API - Verify heartbeat processing with test.deribit.com
3. Add monitoring - Track heartbeat response times and failures

#### Phase 3: Production Hardening
1. Error handling - Graceful degradation on heartbeat failures
2. Supervision - Proper process lifecycle management
3. 24-hour testing - Verify stability under real trading conditions

## Key Learning
The current architecture has Client as a simple struct, but Gun needs a process to send messages to. Without this, no WebSocket messages can be processed, making heartbeat handling impossible. This is a **critical blocker** for financial trading because heartbeat failures result in immediate order cancellation.

## Deribit Heartbeat Requirements
- Must call `set_heartbeat` with interval parameter
- Server sends `test_request` messages  
- Client must respond with `public/test` within timeout
- Failure to respond results in disconnection and order cancellation

## Optimal Clustered Strategy

### Overview
Once the Client GenServer refactor enables heartbeat functionality, clustering becomes a powerful strategy for financial trading resilience. The key insight is: **heartbeat responses stay local** (sub-second requirement), but **heartbeat intelligence gets clustered** (monitoring, failover, scaling decisions).

### Core Clustering Principles

#### Keep Heartbeats Local + Cluster Coordination
```elixir
# Each connection handles its own heartbeats locally
defmodule WebsockexAdapter.Pool.Connection do
  @doc "Each connection handles heartbeats locally"
  def start_connection(exchange_config, pool_name) do
    # Start connection with local heartbeat handling
    {:ok, client} = Client.connect(exchange_config.url, [
      heartbeat_config: exchange_config.heartbeat_config,
      pool_name: pool_name
    ])
    
    # Register with cluster-wide pool coordinator
    PoolCoordinator.register_connection(client, pool_name, node())
    
    {:ok, client}
  end
end
```

#### Cluster-Wide Health Monitoring
```elixir
defmodule WebsockexAdapter.Pool.HeartbeatMonitor do
  @doc "Monitor heartbeat health across entire connection pool"
  def monitor_pool_health(pool_name) do
    pool_connections = get_pool_connections(pool_name)
    
    pool_connections
    |> Enum.map(&get_heartbeat_metrics/1)
    |> aggregate_health_metrics()
    |> evaluate_pool_health()
  end
  
  defp aggregate_health_metrics(metrics_list) do
    %{
      total_connections: length(metrics_list),
      healthy_connections: count_healthy(metrics_list),
      avg_response_time: calculate_avg_response_time(metrics_list),
      failed_connections: count_failed(metrics_list)
    }
  end
end
```

### Risk Distribution Strategies

#### Strategy 1: Order Distribution Across Pool
```elixir
defmodule TradingStrategy.OrderDistribution do
  @doc "Distribute orders across pool to limit blast radius"
  def place_large_order(order, connection_pool) do
    # Split large order across multiple connections
    order_chunks = split_order(order, pool_size: 3)
    
    # Each connection handles its own heartbeats + orders
    order_chunks
    |> Enum.map(fn chunk -> 
      connection = select_healthy_connection(connection_pool)
      place_order(chunk, connection)
    end)
  end
end
```

#### Strategy 2: Rapid Order Re-establishment
```elixir
defmodule FailoverStrategy.OrderRecovery do
  @doc "Quickly re-establish orders when connection fails"
  def handle_connection_failure(failed_connection, connection_pool) do
    # Get cancelled orders from failed connection
    cancelled_orders = get_cancelled_orders(failed_connection)
    
    # Re-establish on healthy connections
    cancelled_orders
    |> Enum.map(fn order ->
      backup_connection = select_backup_connection(connection_pool)
      re_establish_order(order, backup_connection)
    end)
  end
end
```

#### Strategy 3: Geographic Distribution
```elixir
defmodule GeographicStrategy do
  @doc "Distribute connections across geographic regions"
  def start_geographic_pool(exchange) do
    regions = [:us_east, :us_west, :eu_central, :asia_pacific]
    
    regions
    |> Enum.map(fn region ->
      node = select_regional_node(region)
      config = get_regional_config(exchange, region)
      
      :rpc.call(node, Connection, :start_connection, [config, :global_pool])
    end)
  end
end
```

### Coordinated Failover Management

#### Pool-Level Failover Coordination
```elixir
defmodule WebsockexAdapter.Pool.FailoverCoordinator do
  @doc "Replace failed connections in pool"
  def handle_heartbeat_failure(connection_id, pool_name) do
    # Remove failed connection from pool
    :ok = remove_from_pool(connection_id, pool_name)
    
    # Establish replacement connection on best available node
    target_node = select_optimal_node(pool_name)
    
    case establish_replacement_connection(pool_name, target_node) do
      {:ok, new_connection} ->
        add_to_pool(new_connection, pool_name)
        {:ok, :connection_replaced}
        
      {:error, reason} ->
        alert_pool_degradation(pool_name, reason)
        {:error, :replacement_failed}
    end
  end
end
```

#### Intelligent Node Selection
```elixir
defmodule NodeSelector do
  @doc "Select optimal node for new connections"
  def select_optimal_node(pool_name) do
    available_nodes = Node.list([:this, :visible])
    
    available_nodes
    |> Enum.map(&evaluate_node_fitness/1)
    |> Enum.max_by(fn {_node, fitness} -> fitness end)
    |> elem(0)
  end
  
  defp evaluate_node_fitness(node) do
    fitness = %{
      cpu_usage: get_cpu_usage(node),
      memory_usage: get_memory_usage(node),
      network_latency: get_network_latency(node),
      active_connections: count_active_connections(node)
    }
    
    {node, calculate_fitness_score(fitness)}
  end
end
```

### Production Benefits

#### Enhanced Reliability
- **Multiple connections** → If one connection's heartbeats fail, others continue trading
- **Geographic distribution** → Connections closer to exchange servers have better latency
- **Automatic replacement** → Failed connections replaced without manual intervention

#### Performance Optimization
- **Load balancing** → Distribute trading load across multiple connections
- **Latency optimization** → Each connection maintains optimal heartbeat response times
- **Resource isolation** → Heavy trading on one connection doesn't affect others

#### Risk Management Comparison

**Single Connection (High Risk):**
```elixir
single_connection_risk = %{
  heartbeat_failure: :all_orders_cancelled,  # ← CATASTROPHIC
  connection_drop: :all_orders_cancelled,    # ← CATASTROPHIC
  network_issue: :all_orders_cancelled       # ← CATASTROPHIC
}
```

**Clustered Connections (Distributed Risk):**
```elixir
clustered_risk = %{
  one_heartbeat_failure: :some_orders_cancelled,    # ← MANAGEABLE
  one_connection_drop: :some_orders_cancelled,      # ← MANAGEABLE
  one_network_issue: :other_connections_continue    # ← RESILIENT
}
```

### Implementation Roadmap

#### Phase 1: Foundation (Week 1-2)
1. Complete Client GenServer refactor
2. Implement local HeartbeatManager integration
3. Test single connection reliability

#### Phase 2: Basic Pool (Week 3-4)
4. Create connection pool coordinator
5. Implement basic failover logic
6. Test multi-connection scenarios

#### Phase 3: Cluster Coordination (Week 5-6)
7. Add cluster-wide health monitoring
8. Implement intelligent node selection
9. Test cross-node failover scenarios

#### Phase 4: Production Hardening (Week 7-8)
10. Geographic distribution strategies
11. Advanced risk management policies
12. 24/7 production testing

### Key Insight: Why Both Heartbeats AND Clustering

**Heartbeats provide:** Connection-level reliability and exchange compliance
**Clustering provides:** System-level resilience and risk distribution

The combination gives you:
- **Per-connection reliability** (heartbeats ensure each connection stays alive)
- **System-wide resilience** (clustering ensures trading continues despite failures)
- **Controlled risk** (failures affect only subset of orders, not entire portfolio)

Clustering doesn't eliminate the need for heartbeats - it makes heartbeat failures **survivable**.

## Next Steps
1. Start with Client GenServer refactor - This unblocks the entire heartbeat system
2. Maintain test coverage - Ensure all existing functionality continues working
3. Use real API testing - Verify heartbeat processing with actual WebSocket connections