# ZenWebsocket Usage Rules

<!-- This file follows the usage_rules convention for AI agents and developers -->

## Core Principles

1. **Start Simple**: Use direct connection for development, add supervision for production
2. **Only 5 Functions**: The entire public API is just 5 functions
3. **Real API Testing**: Always test against real endpoints, never mock WebSocket behavior

## Quick Start Pattern

```elixir
# Simplest possible usage - connect and send
{:ok, client} = ZenWebsocket.Client.connect("wss://test.deribit.com/ws/api/v2")
ZenWebsocket.Client.send_message(client, Jason.encode!(%{method: "public/test"}))
```

## The 5 Essential Functions

```elixir
# 1. Connect to WebSocket
{:ok, client} = ZenWebsocket.Client.connect(url, opts)

# 2. Send messages
:ok = ZenWebsocket.Client.send_message(client, message)

# 3. Subscribe to channels
{:ok, subscription_id} = ZenWebsocket.Client.subscribe(client, channels)

# 4. Check connection state
state = ZenWebsocket.Client.get_state(client)  # :connected, :connecting, :disconnected

# 5. Close connection
:ok = ZenWebsocket.Client.close(client)
```

## Common Patterns

### Pattern 1: Development/Testing (No Supervision)
```elixir
# Direct connection - crashes won't restart
{:ok, client} = ZenWebsocket.Client.connect(url)
# Use the client...
ZenWebsocket.Client.close(client)
```

### Pattern 2: Production with Dynamic Connections
```elixir
# Add to your supervision tree
children = [
  ZenWebsocket.ClientSupervisor,
  # ... other children
]

# Start connections dynamically
{:ok, client} = ZenWebsocket.ClientSupervisor.start_client(url, opts)
```

### Pattern 3: Production with Fixed Connections
```elixir
# Add specific clients to supervision tree
children = [
  {ZenWebsocket.Client, [
    url: "wss://api.example.com/ws",
    id: :main_websocket,
    heartbeat_config: %{type: :ping, interval: 30_000}
  ]}
]
```

## Configuration Options

```elixir
opts = [
  # Connection
  timeout: 5000,              # Connection timeout in ms
  headers: [],                # Additional headers
  
  # Reconnection
  retry_count: 3,             # Max reconnection attempts
  retry_delay: 1000,          # Initial retry delay (exponential backoff)
  reconnect_on_error: true,   # Auto-reconnect on errors
  
  # Heartbeat
  heartbeat_config: %{
    type: :ping,              # :ping, :pong, :deribit, :custom
    interval: 30_000,         # Heartbeat interval in ms
    message: nil              # Custom heartbeat message (for :custom type)
  }
]
```

## Platform-Specific Rules

### Deribit Integration
```elixir
# Use the Deribit adapter for complete integration
{:ok, adapter} = ZenWebsocket.Examples.DeribitAdapter.start_link([
  url: "wss://test.deribit.com/ws/api/v2",
  client_id: System.get_env("DERIBIT_CLIENT_ID"),
  client_secret: System.get_env("DERIBIT_CLIENT_SECRET")
])

# The adapter handles:
# - Authentication flow
# - Heartbeat/test_request
# - Subscription management
# - Cancel-on-disconnect
```

## Error Handling

```elixir
# All functions return tagged tuples
case ZenWebsocket.Client.connect(url) do
  {:ok, client} -> 
    # Success path
    client
    
  {:error, reason} ->
    # Errors are passed raw from Gun/WebSocket
    # Common errors: :timeout, :connection_refused, :protocol_error
    Logger.error("Connection failed: #{inspect(reason)}")
end
```

## Testing Rules

```elixir
# NEVER mock WebSocket connections
# Use real test endpoints
@tag :integration
test "real WebSocket behavior" do
  {:ok, client} = ZenWebsocket.Client.connect("wss://test.deribit.com/ws/api/v2")
  # Test against real API...
end

# For controlled testing, use MockWebSockServer
{:ok, server} = ZenWebsocket.MockWebSockServer.start(port: 8080)
{:ok, client} = ZenWebsocket.Client.connect("ws://localhost:8080")
```

## DO NOT

1. **Don't create wrapper modules** - Use the 5 functions directly
2. **Don't mock WebSocket behavior** - Test against real endpoints
3. **Don't add custom reconnection** - Use built-in retry options
4. **Don't transform errors** - Handle raw Gun/WebSocket errors
5. **Don't avoid GenServers** - Client uses GenServer appropriately for state

## Architecture Notes

- **Gun Transport**: Built on Gun for HTTP/2 and WebSocket
- **GenServer State**: Client maintains connection state in GenServer
- **ETS Registry**: Fast connection lookups via ETS
- **Exponential Backoff**: Smart reconnection with backoff
- **Real API Testing**: 93 tests, all using real APIs

## Monitoring

```elixir
# Telemetry events are emitted for monitoring
:telemetry.attach(
  "websocket-logger",
  [:zen_websocket, :client, :message_received],
  fn _event, measurements, metadata, _config ->
    Logger.info("Message received: #{measurements.size} bytes")
  end,
  nil
)
```

## Module Limits

Each module follows strict simplicity rules:
- Maximum 5 public functions per module
- Maximum 15 lines per function
- Maximum 2 levels of function calls
- Real API testing only (no mocks)

## Getting Help

- **Examples**: See `lib/zen_websocket/examples/` directory
- **Tests**: Review `test/` for usage patterns
- **Deribit**: See `DeribitAdapter` for complete platform integration

## Common Mistakes to Avoid

1. **Creating abstractions too early** - Start with direct usage
2. **Mocking in tests** - Always use real WebSocket endpoints
3. **Custom error types** - Handle raw Gun/WebSocket errors
4. **Complex supervision** - Use provided patterns (1, 2, or 3)
5. **Ignoring heartbeats** - Configure heartbeat for production

## Migration from Other Libraries

### From Websockex
```elixir
# Old (Websockex with callbacks)
defmodule MyClient do
  use WebSockex
  def handle_frame({:text, msg}, state), do: {:ok, state}
end

# New (ZenWebsocket - simpler)
{:ok, client} = ZenWebsocket.Client.connect(url)
# Messages handled via message_handler configuration
```

### From Gun directly
```elixir
# You're already using the right approach!
# ZenWebsocket is a thin, focused layer over Gun
```

## Performance Characteristics

- **Connection Time**: < 100ms typical
- **Message Latency**: < 1ms processing
- **Memory**: ~50KB per connection
- **Reconnection**: Exponential backoff (1s, 2s, 4s...)
- **Concurrency**: Thousands of simultaneous connections

## Required Environment Variables

For platform integrations:
```bash
# Deribit
export DERIBIT_CLIENT_ID="your_client_id"
export DERIBIT_CLIENT_SECRET="your_client_secret"
```

## Best Practices Summary

1. Start with Pattern 1 (direct) for development
2. Move to Pattern 2 or 3 for production
3. Configure heartbeats for long-lived connections
4. Test against real endpoints
5. Handle raw errors with pattern matching
6. Use telemetry for monitoring
7. Keep it simple - just 5 functions!