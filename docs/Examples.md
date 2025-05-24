# WebsockexAdapter Examples

This guide provides practical examples of using WebsockexAdapter in various scenarios.

## Basic Usage

### Simple Echo Server Connection

```elixir
# Connect to an echo WebSocket server
{:ok, client} = WebsockexAdapter.Client.connect("wss://echo.websocket.org")

# Send a message
{:ok, _} = WebsockexAdapter.Client.send_message(client, "Hello, WebSocket!")

# Messages are received as process messages
receive do
  {:websocket_message, message} ->
    IO.puts("Received: #{inspect(message)}")
after
  5000 -> IO.puts("No message received")
end

# Close the connection
:ok = WebsockexAdapter.Client.close(client)
```

### Connection with Custom Headers

```elixir
config = %WebsockexAdapter.Config{
  url: "wss://api.example.com/ws",
  headers: [
    {"Authorization", "Bearer #{token}"},
    {"X-API-Version", "2.0"}
  ],
  timeout: 10_000
}

{:ok, client} = WebsockexAdapter.Client.connect(config)
```

## Subscription Management

### Subscribe to Multiple Channels

```elixir
{:ok, client} = WebsockexAdapter.Client.connect("wss://stream.example.com")

# Subscribe to multiple data streams
channels = ["trades.BTC-USD", "orderbook.ETH-USD", "ticker.SOL-USD"]
{:ok, _} = WebsockexAdapter.Client.subscribe(client, channels)

# Handle incoming market data
def handle_market_data(client) do
  receive do
    {:websocket_message, %{"channel" => channel, "data" => data}} ->
      process_market_update(channel, data)
      handle_market_data(client)
    
    {:websocket_closed, reason} ->
      Logger.info("Connection closed: #{inspect(reason)}")
  end
end
```

## Error Handling

### Handling Connection Failures

```elixir
defmodule MyWebSocketClient do
  use GenServer
  require Logger

  def start_link(url) do
    GenServer.start_link(__MODULE__, url)
  end

  def init(url) do
    case WebsockexAdapter.Client.connect(url) do
      {:ok, client} ->
        {:ok, %{client: client, url: url}}
      
      {:error, reason} ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        # Retry after delay
        Process.send_after(self(), :retry_connect, 5_000)
        {:ok, %{client: nil, url: url}}
    end
  end

  def handle_info(:retry_connect, %{url: url} = state) do
    case WebsockexAdapter.Client.connect(url) do
      {:ok, client} ->
        Logger.info("Reconnected successfully")
        {:noreply, %{state | client: client}}
      
      {:error, _reason} ->
        Process.send_after(self(), :retry_connect, 5_000)
        {:noreply, state}
    end
  end

  def handle_info({:websocket_message, message}, state) do
    # Process incoming messages
    process_message(message)
    {:noreply, state}
  end
end
```

## JSON-RPC Integration

### Making JSON-RPC Calls

```elixir
defmodule JsonRpcClient do
  def call_method(client, method, params) do
    request = WebsockexAdapter.JsonRpc.encode_request(method, params)
    
    case WebsockexAdapter.Client.send_message(client, request) do
      {:ok, _} ->
        receive do
          {:websocket_message, response} ->
            WebsockexAdapter.JsonRpc.decode_response(response)
        after
          5_000 -> {:error, :timeout}
        end
      
      error -> error
    end
  end
end

# Usage
{:ok, client} = WebsockexAdapter.Client.connect("wss://api.example.com/jsonrpc")
{:ok, result} = JsonRpcClient.call_method(client, "get_balance", %{currency: "USD"})
```

## Rate Limiting

### Configuring Rate Limits

```elixir
# Create a rate limiter for API compliance
{:ok, limiter} = WebsockexAdapter.RateLimiter.start_link(
  rate: 10,           # 10 requests per second
  burst: 20,          # Allow bursts up to 20
  refill_interval: 100 # Refill every 100ms
)

# Use with client
defmodule RateLimitedClient do
  def send_order(client, limiter, order) do
    case WebsockexAdapter.RateLimiter.check_rate(limiter) do
      :ok ->
        WebsockexAdapter.Client.send_message(client, order)
      
      {:error, :rate_limited} ->
        {:error, :rate_limited}
    end
  end
end
```

## Supervised Connections

### Using the Client Supervisor

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {WebsockexAdapter.ClientSupervisor, name: MyApp.ClientSupervisor},
      MyApp.ConnectionManager
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule MyApp.ConnectionManager do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # Start supervised connections
    {:ok, client1} = WebsockexAdapter.ClientSupervisor.start_client(
      MyApp.ClientSupervisor,
      "wss://stream1.example.com"
    )
    
    {:ok, client2} = WebsockexAdapter.ClientSupervisor.start_client(
      MyApp.ClientSupervisor,
      "wss://stream2.example.com"
    )
    
    {:ok, %{clients: [client1, client2]}}
  end
end
```

## Custom Adapters

### Building a Custom Exchange Adapter

```elixir
defmodule MyExchangeAdapter do
  use GenServer
  require Logger

  defstruct [:client, :api_key, :subscriptions]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    url = Keyword.fetch!(opts, :url)
    api_key = Keyword.fetch!(opts, :api_key)
    
    case WebsockexAdapter.Client.connect(url) do
      {:ok, client} ->
        # Authenticate on connection
        auth_message = %{
          "method" => "auth",
          "params" => %{"api_key" => api_key}
        }
        WebsockexAdapter.Client.send_message(client, Jason.encode!(auth_message))
        
        {:ok, %__MODULE__{
          client: client,
          api_key: api_key,
          subscriptions: MapSet.new()
        }}
      
      {:error, reason} ->
        {:stop, reason}
    end
  end

  def subscribe(adapter, channels) do
    GenServer.call(adapter, {:subscribe, channels})
  end

  def handle_call({:subscribe, channels}, _from, state) do
    message = %{
      "method" => "subscribe",
      "params" => %{"channels" => channels}
    }
    
    case WebsockexAdapter.Client.send_message(state.client, Jason.encode!(message)) do
      {:ok, _} ->
        new_subs = Enum.reduce(channels, state.subscriptions, &MapSet.put(&2, &1))
        {:reply, :ok, %{state | subscriptions: new_subs}}
      
      error ->
        {:reply, error, state}
    end
  end

  def handle_info({:websocket_message, message}, state) do
    case Jason.decode(message) do
      {:ok, %{"type" => "data", "channel" => channel} = data} ->
        handle_channel_data(channel, data)
      
      {:ok, %{"type" => "error"} = error} ->
        Logger.error("Exchange error: #{inspect(error)}")
      
      _ ->
        Logger.debug("Unknown message: #{inspect(message)}")
    end
    
    {:noreply, state}
  end

  defp handle_channel_data(channel, data) do
    # Process channel-specific data
    :ok
  end
end
```

## Testing Patterns

### Integration Testing with Real APIs

```elixir
defmodule MyWebSocketTest do
  use ExUnit.Case

  @tag :integration
  test "connects and receives market data" do
    # Use test environment
    url = System.get_env("TEST_WS_URL") || "wss://test.api.example.com"
    
    {:ok, client} = WebsockexAdapter.Client.connect(url)
    {:ok, _} = WebsockexAdapter.Client.subscribe(client, ["test.channel"])
    
    assert_receive {:websocket_message, _message}, 5_000
    
    :ok = WebsockexAdapter.Client.close(client)
  end
  
  @tag :integration
  test "handles reconnection on network failure" do
    {:ok, client} = WebsockexAdapter.Client.connect("wss://test.api.example.com")
    
    # Get the underlying Gun process
    state = WebsockexAdapter.Client.get_state(client)
    
    # Simulate connection drop
    Process.exit(state.gun_pid, :kill)
    
    # Wait for reconnection
    Process.sleep(2_000)
    
    # Verify connection is restored
    new_state = WebsockexAdapter.Client.get_state(client)
    assert new_state.status == :connected
  end
end
```

## Performance Optimization

### High-Frequency Message Handling

```elixir
defmodule HighFrequencyHandler do
  use GenServer

  def init(url) do
    {:ok, client} = WebsockexAdapter.Client.connect(url)
    
    # Use a buffer for batch processing
    {:ok, %{
      client: client,
      buffer: [],
      timer: schedule_flush()
    }}
  end

  def handle_info({:websocket_message, message}, state) do
    # Buffer messages for batch processing
    {:noreply, %{state | buffer: [message | state.buffer]}}
  end

  def handle_info(:flush_buffer, state) do
    if state.buffer != [] do
      # Process all buffered messages at once
      process_batch(Enum.reverse(state.buffer))
    end
    
    {:noreply, %{state | buffer: [], timer: schedule_flush()}}
  end

  defp schedule_flush do
    Process.send_after(self(), :flush_buffer, 100) # Flush every 100ms
  end

  defp process_batch(messages) do
    # Efficient batch processing
    Enum.group_by(messages, & &1["type"])
    |> Enum.each(fn {type, msgs} ->
      process_message_type(type, msgs)
    end)
  end
end
```

## Monitoring and Telemetry

### Adding Custom Telemetry

```elixir
defmodule TelemetryClient do
  def connect_with_telemetry(url) do
    start_time = System.monotonic_time()
    
    result = WebsockexAdapter.Client.connect(url)
    
    duration = System.monotonic_time() - start_time
    
    :telemetry.execute(
      [:my_app, :websocket, :connect],
      %{duration: duration},
      %{url: url, status: elem(result, 0)}
    )
    
    result
  end
  
  def setup_telemetry_handler do
    :telemetry.attach(
      "websocket-metrics",
      [:my_app, :websocket, :connect],
      &handle_event/4,
      nil
    )
  end
  
  defp handle_event(_event_name, measurements, metadata, _config) do
    IO.puts("WebSocket connection took #{measurements.duration / 1_000_000}ms to #{metadata.url}")
  end
end
```