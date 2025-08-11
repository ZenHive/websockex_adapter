# JSON-RPC Elixir Analysis

Analysis of the `json_rpc_elixir` library for potential improvements and patterns that could benefit ZenWebsocket.

## Library Overview

The `json_rpc_elixir` library is a JSON-RPC 2.0 implementation in Elixir with WebSocket client capabilities. It uses WebSockex as the underlying WebSocket library and provides a clean API for making JSON-RPC calls over WebSocket connections.

## Key Architectural Patterns

### 1. Request/Response Correlation Pattern

**json_rpc_elixir approach:**
```elixir
# Handler maintains id_to_pid mapping
%State{
  next_id: 0,
  id_to_pid: %{},  # Maps request ID to calling process PID
  time_before_reconnect: 100,
  unrecognized_frame_handler: unrecognized_frame_handler
}

# Async call pattern with receive
def call_with_params(client, method, params, timeout \\ @default_timeout) do
  send(client, {:call_with_params, {self(), method, params}})
  receive_response(client, timeout)
end

defp receive_response(client, timeout) do
  receive do
    {:json_rpc_frame, response} -> {:ok, response}
    {:json_rpc_error, reason} -> {:error, reason}
  after
    timeout ->
      send(client, {:timeout_request, self()})
      # Double-receive pattern for race conditions
      receive do
        {:json_rpc_frame, response} -> {:ok, response}
        {:json_rpc_error, reason} -> {:error, reason}
      after
        0 -> {:error, :timeout}
      end
  end
end
```

**ZenWebsocket current approach:**
```elixir
# Simple macro-based request building
defmacro defrpc(name, method, opts \\ []) do
  quote do
    def unquote(name)(params \\ %{}) do
      ZenWebsocket.JsonRpc.build_request(unquote(method), params)
    end
  end
end

# Basic response matching
def match_response(%{"result" => result}), do: {:ok, result}
def match_response(%{"error" => %{"code" => code, "message" => message}}) do
  {:error, {code, message}}
end
```

### 2. Reconnection Strategy

**json_rpc_elixir approach:**
```elixir
def handle_disconnect(connection_status_map, state) do
  # Notify all pending callers
  Enum.each(state.id_to_pid, fn {_id, pid} ->
    send_connection_closed_error(pid)
  end)

  # Exponential backoff with spawn
  parent_pid = self()
  spawn(fn ->
    Process.sleep(state.time_before_reconnect)
    send(parent_pid, :reconnect)
  end)

  # Clear message queue and reset state
  clear_messages()
  state = %State{state | id_to_pid: %{}}
  state = %State{state | time_before_reconnect: min(state.time_before_reconnect * 2, 5_000)}
  {:reconnect, state}
end
```

**ZenWebsocket current approach:**
```elixir
# Uses Gun with separate reconnection module
# More sophisticated with actual WebSocket lifecycle management
# But could benefit from the queue clearing pattern
```

### 3. Error Handling Patterns

**json_rpc_elixir approach:**
```elixir
# Defensive error handling in frame processing
try do
  do_handle_frame(frame, state)
  |> case do
    {:error, state} ->
      state.unrecognized_frame_handler.(frame)
      {:ok, state}
    {:ok, state} ->
      {:ok, state}
  end
rescue
  error ->
    log_message("Error in handle_frame/2 with frame #{inspect(frame)}")
    {:ok, state}
end
```

## Potential Improvements for ZenWebsocket

### 1. Enhanced Request/Response Correlation

**Recommendation:** Add async call pattern support to ZenWebsocket

```elixir
# Potential addition to ZenWebsocket.Client
def call_async(client, method, params, timeout \\ 5000) do
  {:ok, request} = JsonRpc.build_request(method, params)
  request_id = request["id"]
  
  :ok = send_message(client, Jason.encode!(request))
  
  receive do
    {:websocket_response, ^request_id, response} -> {:ok, response}
    {:websocket_error, ^request_id, error} -> {:error, error}
  after
    timeout -> {:error, :timeout}
  end
end
```

**Benefits:**
- Simplified async request/response handling
- Built-in timeout management
- Race condition protection

### 2. Message Queue Management During Reconnection

**Current gap:** ZenWebsocket doesn't clear pending requests during reconnection.

**Recommendation:** Add queue clearing similar to json_rpc_elixir:

```elixir
defp clear_pending_requests(state) do
  # Notify all pending callers about connection loss
  Enum.each(state.pending_requests, fn {_id, pid} ->
    send(pid, {:websocket_error, :connection_closed})
  end)
  
  # Clear message queue
  clear_messages()
  
  %{state | pending_requests: %{}}
end

defp clear_messages do
  receive do
    {:call_request, {pid, _request}} ->
      send(pid, {:websocket_error, :connection_closed})
      clear_messages()
    _ ->
      clear_messages()
  after
    0 -> :ok
  end
end
```

### 3. Unrecognized Frame Handler Pattern

**Recommendation:** Add configurable unrecognized frame handler:

```elixir
# In ZenWebsocket.Config
defstruct [
  # ... existing fields
  unrecognized_frame_handler: &default_unrecognized_handler/1
]

defp default_unrecognized_handler(frame) do
  Logger.warn("Unrecognized WebSocket frame: #{inspect(frame)}")
end
```

### 4. Double-Receive Pattern for Race Conditions

**Current gap:** ZenWebsocket doesn't handle timeout race conditions.

**Recommendation:** Implement double-receive pattern:

```elixir
defp receive_response(timeout) do
  receive do
    {:websocket_response, response} -> {:ok, response}
    {:websocket_error, error} -> {:error, error}
  after
    timeout ->
      # Handle race condition where response arrives during timeout
      receive do
        {:websocket_response, response} -> {:ok, response}
        {:websocket_error, error} -> {:error, error}
      after
        0 -> {:error, :timeout}
      end
  end
end
```

## Architectural Differences

### WebSockex vs Gun

**json_rpc_elixir (WebSockex):**
- Higher-level WebSocket abstraction
- Built-in reconnection handling
- Simpler state management
- Less control over underlying transport

**ZenWebsocket (Gun):**
- Lower-level HTTP/2 + WebSocket client
- More transport control
- Better performance characteristics
- More complex state management required

### State Management Philosophy

**json_rpc_elixir:**
- Single WebSockex process manages all state
- Simple struct-based state
- Message passing for async operations

**ZenWebsocket:**
- Separation of concerns (Client, Registry, Reconnection)
- ETS for connection tracking
- More modular architecture

## Recommendations Summary

### High Priority
1. **Add async call pattern** - Critical for request/response correlation
2. **Implement queue clearing** - Prevents message leaks during reconnection
3. **Add double-receive pattern** - Handles timeout race conditions

### Medium Priority
1. **Unrecognized frame handler** - Better debugging and extensibility
2. **Enhanced error categorization** - Learn from json_rpc_elixir's defensive patterns

### Low Priority
1. **Batch request support** - json_rpc_elixir has batch response parsing
2. **Configurable logging** - json_rpc_elixir's conditional logging pattern

## Implementation Notes

All recommendations should follow ZenWebsocket's simplicity principles:
- Maximum 5 functions per module
- Maximum 15 lines per function
- Real API testing only
- Maintain Gun-based architecture
- Follow existing error handling patterns

The json_rpc_elixir library provides excellent patterns for async request handling and defensive programming that could significantly improve ZenWebsocket's robustness while maintaining its architectural simplicity.

## Could json_rpc_elixir Use ZenWebsocket?

**Short Answer: Yes, with some integration work.**

### Migration Feasibility Analysis

**Current json_rpc_elixir Architecture:**
```elixir
# WebSockex-based client
WebSockex.start_link(conn, Handler, state, opts)

# Direct WebSockex API calls
def call_with_params(client, method, params, timeout) do
  send(client, {:call_with_params, {self(), method, params}})
  receive_response(client, timeout)
end
```

**Potential ZenWebsocket Integration:**
```elixir
# ZenWebsocket-based client  
{:ok, client} = ZenWebsocket.Client.connect(url, opts)

# Async call pattern using ZenWebsocket
def call_with_params(client, method, params, timeout) do
  {:ok, request} = build_json_rpc_request(method, params)
  ZenWebsocket.Client.send_message(client, Jason.encode!(request))
  receive_response(request["id"], timeout)
end
```

### Technical Integration Challenges

#### 1. **Message Ownership Pattern**
**json_rpc_elixir:** Uses WebSockex process that receives all frames
**ZenWebsocket:** Uses Gun with GenServer that owns connections

**Solution:** Create JSON-RPC adapter layer that bridges the ownership models:
```elixir
defmodule JsonRpc.Client.ZenWebsocket do
  use GenServer
  
  def start_link(url, opts \\ []) do
    GenServer.start_link(__MODULE__, {url, opts})
  end
  
  def init({url, opts}) do
    {:ok, client} = ZenWebsocket.Client.connect(url, [
      message_handler: {__MODULE__, :handle_websocket_message, [self()]}
    ])
    
    state = %{
      client: client,
      next_id: 0,
      id_to_pid: %{}
    }
    
    {:ok, state}
  end
  
  def handle_websocket_message(frame, server_pid) do
    send(server_pid, {:websocket_frame, frame})
  end
end
```

#### 2. **API Compatibility**
**Challenge:** json_rpc_elixir expects specific WebSockex client interface

**Solution:** Create compatibility wrapper:
```elixir
# Wrapper to maintain json_rpc_elixir API compatibility
defmodule JsonRpc.Client.ZenWebsocketWrapper do
  def start_link(conn, opts \\ []) do
    # Convert WebSockex options to ZenWebsocket options
    adapter_opts = convert_websockex_opts(opts)
    JsonRpc.Client.ZenWebsocket.start_link(conn, adapter_opts)
  end
  
  def call_with_params(client, method, params, timeout) do
    # Delegate to ZenWebsocket-based implementation
    JsonRpc.Client.ZenWebsocket.call_with_params(client, method, params, timeout)
  end
end
```

#### 3. **State Management Differences**
**json_rpc_elixir:** Single process with struct-based state
**ZenWebsocket:** Multi-process with registry-based tracking

**Solution:** Maintain compatibility through state abstraction:
```elixir
defmodule JsonRpc.StateAdapter do
  def from_websockex_state(websockex_state) do
    %{
      client: websockex_state.client,
      id_to_pid: websockex_state.id_to_pid,
      next_id: websockex_state.next_id
    }
  end
  
  def to_websockex_compatible(adapter_state) do
    # Convert ZenWebsocket state back to json_rpc_elixir format
  end
end
```

### Integration Benefits

#### 1. **Performance Improvements**
- **Gun transport:** HTTP/2 multiplexing, better connection pooling
- **ETS registry:** Faster connection lookups
- **Process efficiency:** Better resource utilization

#### 2. **Enhanced Reliability**
- **Robust reconnection:** ZenWebsocket's proven reconnection logic
- **Connection monitoring:** Better failure detection and recovery
- **Financial-grade stability:** Tested with real trading APIs

#### 3. **Feature Enhancements**
- **Rate limiting:** Built-in rate limiting capabilities
- **Heartbeat management:** Integrated keepalive functionality
- **Error categorization:** Comprehensive error handling

### Migration Path

#### Phase 1: Compatibility Layer
```elixir
# Create drop-in replacement
defmodule JsonRpc.Client.ZenWebsocket do
  # Implement WebSockex-compatible API using ZenWebsocket
  def start_link(conn, opts), do: # ...
  def call_with_params(client, method, params, timeout), do: # ...
  def call_without_params(client, method, timeout), do: # ...
  def notify_with_params(client, method, params), do: # ...
  def notify_without_params(client, method), do: # ...
end
```

#### Phase 2: Enhanced Integration
```elixir
# Add ZenWebsocket-specific features
use JsonRpc.ApiCreator, [
  %{
    method: "getUser",
    zen_websocket_opts: [
      rate_limit: {100, :per_minute},
      heartbeat_interval: 30_000,
      reconnect_strategy: :exponential_backoff
    ]
  }
]
```

#### Phase 3: Native Integration
```elixir
# Rewrite json_rpc_elixir to use ZenWebsocket natively
defmodule JsonRpc.Client.Native do
  @behaviour ZenWebsocket.MessageHandler
  
  def handle_message({:text, data}, state) do
    case Jason.decode(data) do
      {:ok, response} -> handle_json_rpc_response(response, state)
      {:error, _} -> {:ok, state}
    end
  end
end
```

### Conclusion

**Yes, json_rpc_elixir could definitely use ZenWebsocket.** The migration would provide significant benefits in terms of performance, reliability, and features. The main challenges are:

1. **API compatibility** - Solvable with wrapper layers
2. **Message ownership** - Requires adapter pattern
3. **State management** - Needs abstraction layer

The integration would be particularly valuable for:
- **High-frequency trading applications** 
- **Production financial systems**
- **Applications requiring robust reconnection**
- **Systems needing integrated rate limiting**

The migration could be done incrementally, starting with a compatibility layer and eventually moving to native ZenWebsocket integration.