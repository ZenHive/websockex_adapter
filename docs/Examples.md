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

## Deribit Exchange Adapter

### Using the Real Deribit Adapter

```elixir
# Basic connection with authentication
{:ok, adapter} = WebsockexAdapter.Examples.DeribitAdapter.connect(
  client_id: System.get_env("DERIBIT_CLIENT_ID"),
  client_secret: System.get_env("DERIBIT_CLIENT_SECRET"),
  url: "wss://test.deribit.com/ws/api/v2"
)

# Subscribe to market data
{:ok, _} = WebsockexAdapter.Examples.DeribitAdapter.subscribe(adapter, [
  "book.BTC-PERPETUAL.raw",
  "trades.BTC-PERPETUAL.raw"
])

# Place an order
{:ok, order} = WebsockexAdapter.Examples.DeribitAdapter.buy(
  adapter,
  instrument_name: "BTC-PERPETUAL",
  amount: 100,
  type: "limit",
  price: 45000
)

# Get account summary
{:ok, summary} = WebsockexAdapter.Examples.DeribitAdapter.get_account_summary(
  adapter,
  currency: "BTC"
)
```

### Using the Supervised GenServer Adapter

```elixir
# Start the supervised adapter
{:ok, adapter} = WebsockexAdapter.Examples.DeribitGenServerAdapter.start_link(
  name: MyApp.DeribitAdapter,
  client_id: System.get_env("DERIBIT_CLIENT_ID"),
  client_secret: System.get_env("DERIBIT_CLIENT_SECRET")
)

# Authenticate (automatic on reconnection)
{:ok, _} = WebsockexAdapter.Examples.DeribitGenServerAdapter.authenticate(adapter)

# Subscribe to channels (automatically restored on reconnection)
{:ok, _} = WebsockexAdapter.Examples.DeribitGenServerAdapter.subscribe(adapter, [
  "ticker.BTC-PERPETUAL.raw",
  "book.ETH-PERPETUAL.100ms"
])

# The adapter handles:
# - Automatic reconnection on connection loss
# - Re-authentication after reconnection
# - Subscription restoration
# - Heartbeat management
```

### Advanced Deribit Features

```elixir
defmodule MyTradingSystem do
  alias WebsockexAdapter.Examples.DeribitGenServerAdapter, as: Deribit
  
  def setup_risk_management(adapter) do
    # Enable cancel-on-disconnect for safety
    {:ok, _} = Deribit.send_request(adapter, "private/enable_cancel_on_disconnect")
    
    # Set heartbeat interval
    {:ok, _} = Deribit.send_request(adapter, "public/set_heartbeat", %{
      interval: 30
    })
  end
  
  def get_market_state(adapter, instrument) do
    # Get multiple data points in parallel
    tasks = [
      Task.async(fn -> Deribit.get_order_book(adapter, instrument_name: instrument) end),
      Task.async(fn -> Deribit.ticker(adapter, instrument_name: instrument) end),
      Task.async(fn -> Deribit.get_instruments(adapter, currency: "BTC", kind: "future") end)
    ]
    
    [order_book, ticker, instruments] = Task.await_many(tasks)
    
    %{
      order_book: order_book,
      ticker: ticker,
      instruments: instruments
    }
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

### High-Frequency Deribit Market Data Handler

```elixir
defmodule DeribitMarketDataHandler do
  use GenServer
  require Logger
  
  alias WebsockexAdapter.Examples.DeribitAdapter

  defstruct [:adapter, :buffer, :timer, :instruments, :batch_size, :flush_interval]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    # Connect to Deribit
    {:ok, adapter} = DeribitAdapter.connect(
      client_id: opts[:client_id],
      client_secret: opts[:client_secret],
      handler: self()  # Route messages to this GenServer
    )
    
    # Subscribe to high-frequency channels
    instruments = opts[:instruments] || ["BTC-PERPETUAL", "ETH-PERPETUAL"]
    channels = Enum.flat_map(instruments, fn inst ->
      ["book.#{inst}.100ms", "trades.#{inst}.raw"]
    end)
    
    {:ok, _} = DeribitAdapter.subscribe(adapter, channels)
    
    state = %__MODULE__{
      adapter: adapter,
      buffer: %{orderbook: [], trades: []},
      instruments: instruments,
      batch_size: opts[:batch_size] || 1000,
      flush_interval: opts[:flush_interval] || 100,
      timer: schedule_flush(opts[:flush_interval] || 100)
    }
    
    {:ok, state}
  end

  # Handle incoming market data
  def handle_info({:websocket_message, %{"params" => %{"channel" => channel, "data" => data}}}, state) do
    # Route to appropriate buffer
    state = 
      cond do
        String.contains?(channel, "book.") ->
          %{state | buffer: Map.update!(state.buffer, :orderbook, &[{channel, data} | &1])}
        
        String.contains?(channel, "trades.") ->
          %{state | buffer: Map.update!(state.buffer, :trades, &[{channel, data} | &1])}
        
        true ->
          state
      end
    
    # Check if we should flush early due to buffer size
    if total_buffer_size(state.buffer) >= state.batch_size do
      send(self(), :flush_buffer)
    end
    
    {:noreply, state}
  end

  # Periodic flush
  def handle_info(:flush_buffer, state) do
    if not empty_buffer?(state.buffer) do
      # Process orderbook updates
      if state.buffer.orderbook != [] do
        process_orderbook_batch(Enum.reverse(state.buffer.orderbook))
      end
      
      # Process trades
      if state.buffer.trades != [] do
        process_trades_batch(Enum.reverse(state.buffer.trades))
      end
    end
    
    # Reset buffer and schedule next flush
    {:noreply, %{state | 
      buffer: %{orderbook: [], trades: []},
      timer: schedule_flush(state.flush_interval)
    }}
  end

  # Batch processing functions
  defp process_orderbook_batch(updates) do
    # Group by instrument for efficient processing
    updates
    |> Enum.group_by(fn {channel, _} -> extract_instrument(channel) end)
    |> Enum.each(fn {instrument, book_updates} ->
      # Merge orderbook updates efficiently
      merged_book = merge_orderbook_updates(book_updates)
      
      # Store or forward to trading strategy
      :telemetry.execute(
        [:deribit, :orderbook, :batch_processed],
        %{count: length(book_updates), instrument: instrument},
        %{book_depth: calculate_depth(merged_book)}
      )
    end)
  end
  
  defp process_trades_batch(trades) do
    # Calculate VWAP and volume metrics per instrument
    trades
    |> Enum.group_by(fn {channel, _} -> extract_instrument(channel) end)
    |> Enum.each(fn {instrument, trade_list} ->
      stats = calculate_trade_statistics(trade_list)
      
      :telemetry.execute(
        [:deribit, :trades, :batch_processed],
        Map.merge(stats, %{count: length(trade_list), instrument: instrument}),
        %{}
      )
    end)
  end
  
  # Helper functions
  defp schedule_flush(interval) do
    Process.send_after(self(), :flush_buffer, interval)
  end
  
  defp total_buffer_size(buffer) do
    length(buffer.orderbook) + length(buffer.trades)
  end
  
  defp empty_buffer?(buffer) do
    buffer.orderbook == [] and buffer.trades == []
  end
  
  defp extract_instrument(channel) do
    channel |> String.split(".") |> Enum.at(1)
  end
  
  defp merge_orderbook_updates(updates) do
    # Implement efficient orderbook merging logic
    # This is a simplified version
    List.last(updates)
  end
  
  defp calculate_depth(book) do
    # Calculate book depth metrics
    %{
      bid_depth: length(book["bids"] || []),
      ask_depth: length(book["asks"] || [])
    }
  end
  
  defp calculate_trade_statistics(trades) do
    # Calculate VWAP and volume
    {total_volume, total_value} = 
      Enum.reduce(trades, {0, 0}, fn {_, data}, {vol, val} ->
        trade_vol = data["amount"] || 0
        trade_price = data["price"] || 0
        {vol + trade_vol, val + (trade_vol * trade_price)}
      end)
    
    vwap = if total_volume > 0, do: total_value / total_volume, else: 0
    
    %{
      volume: total_volume,
      vwap: vwap,
      trade_count: length(trades)
    }
  end
end
```

## Monitoring and Telemetry

### Deribit Adapter with Telemetry

```elixir
defmodule DeribitTelemetryAdapter do
  @moduledoc """
  Wraps DeribitAdapter with comprehensive telemetry for monitoring.
  """
  
  alias WebsockexAdapter.Examples.DeribitAdapter
  require Logger

  # Connection metrics
  def connect_with_telemetry(opts) do
    start_time = System.monotonic_time()
    
    result = DeribitAdapter.connect(opts)
    
    duration = System.monotonic_time() - start_time
    
    :telemetry.execute(
      [:deribit, :connection, :attempt],
      %{duration: duration},
      %{url: opts[:url] || "wss://test.deribit.com/ws/api/v2", status: elem(result, 0)}
    )
    
    case result do
      {:ok, adapter} ->
        # Start monitoring connection health
        spawn_link(fn -> monitor_connection_health(adapter) end)
        {:ok, adapter}
      
      error ->
        error
    end
  end
  
  # Request/Response metrics
  def send_request_with_telemetry(adapter, method, params \ %{}) do
    start_time = System.monotonic_time()
    
    result = DeribitAdapter.send_request(adapter, method, params)
    
    duration = System.monotonic_time() - start_time
    
    :telemetry.execute(
      [:deribit, :request, :complete],
      %{duration: duration},
      %{method: method, status: elem(result, 0)}
    )
    
    result
  end
  
  # Subscription metrics
  def subscribe_with_telemetry(adapter, channels) do
    start_time = System.monotonic_time()
    
    result = DeribitAdapter.subscribe(adapter, channels)
    
    duration = System.monotonic_time() - start_time
    
    :telemetry.execute(
      [:deribit, :subscription, :attempt],
      %{duration: duration, channel_count: length(channels)},
      %{channels: channels, status: elem(result, 0)}
    )
    
    result
  end
  
  # Setup telemetry handlers
  def setup_telemetry_handlers do
    events = [
      [:deribit, :connection, :attempt],
      [:deribit, :request, :complete],
      [:deribit, :subscription, :attempt],
      [:deribit, :orderbook, :batch_processed],
      [:deribit, :trades, :batch_processed],
      [:deribit, :connection, :health]
    ]
    
    :telemetry.attach_many(
      "deribit-metrics",
      events,
      &handle_telemetry_event/4,
      nil
    )
  end
  
  defp handle_telemetry_event([:deribit, :connection, :attempt], measurements, metadata, _) do
    Logger.info("Deribit connection #{metadata.status} in #{measurements.duration / 1_000_000}ms to #{metadata.url}")
  end
  
  defp handle_telemetry_event([:deribit, :request, :complete], measurements, metadata, _) do
    if measurements.duration > 100_000_000 do  # Log slow requests (>100ms)
      Logger.warning("Slow Deribit request #{metadata.method} took #{measurements.duration / 1_000_000}ms")
    end
  end
  
  defp handle_telemetry_event([:deribit, :orderbook, :batch_processed], measurements, metadata, _) do
    Logger.debug("Processed #{measurements.count} orderbook updates for #{measurements.instrument}")
  end
  
  defp handle_telemetry_event([:deribit, :trades, :batch_processed], measurements, metadata, _) do
    Logger.info("#{measurements.instrument}: #{measurements.trade_count} trades, " <>
                "volume: #{measurements.volume}, VWAP: #{Float.round(measurements.vwap, 2)}")
  end
  
  defp handle_telemetry_event([:deribit, :connection, :health], measurements, _metadata, _) do
    if measurements.latency > 1000 do
      Logger.warning("High Deribit connection latency: #{measurements.latency}ms")
    end
  end
  
  # Connection health monitoring
  defp monitor_connection_health(adapter) do
    Process.sleep(30_000)  # Check every 30 seconds
    
    case DeribitAdapter.test_request(adapter) do
      {:ok, %{"result" => _}} ->
        :telemetry.execute(
          [:deribit, :connection, :health],
          %{latency: 50, status: :healthy},  # You'd measure actual latency
          %{}
        )
        
      {:error, reason} ->
        Logger.error("Deribit health check failed: #{inspect(reason)}")
        :telemetry.execute(
          [:deribit, :connection, :health],
          %{latency: 0, status: :unhealthy},
          %{error: reason}
        )
    end
    
    monitor_connection_health(adapter)
  end
end

# Usage example
defmodule MyApp.Application do
  def start(_type, _args) do
    # Setup telemetry handlers
    DeribitTelemetryAdapter.setup_telemetry_handlers()
    
    # Connect with telemetry
    {:ok, adapter} = DeribitTelemetryAdapter.connect_with_telemetry(
      client_id: System.get_env("DERIBIT_CLIENT_ID"),
      client_secret: System.get_env("DERIBIT_CLIENT_SECRET")
    )
    
    # Use the adapter with automatic telemetry
    {:ok, _} = DeribitTelemetryAdapter.subscribe_with_telemetry(adapter, [
      "book.BTC-PERPETUAL.raw",
      "trades.ETH-PERPETUAL.raw"
    ])
    
    # Start your application
    children = [
      {DeribitMarketDataHandler, 
        name: MyApp.MarketData,
        client_id: System.get_env("DERIBIT_CLIENT_ID"),
        client_secret: System.get_env("DERIBIT_CLIENT_SECRET"),
        instruments: ["BTC-PERPETUAL", "ETH-PERPETUAL"],
        batch_size: 500,
        flush_interval: 50
      }
    ]
    
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```