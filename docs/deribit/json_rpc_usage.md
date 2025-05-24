# Deribit JSON-RPC Macro Usage Patterns

This guide demonstrates how to use the JSON-RPC macro-generated methods for common market making and trading workflows with Deribit.

## Overview

The WebsockexAdapter.JsonRpc module provides a `defrpc` macro that automatically generates functions for JSON-RPC 2.0 API calls. The Deribit adapter includes 29 pre-defined methods covering authentication, market data, trading, and risk management.

## Basic Usage

```elixir
# Connect to Deribit
{:ok, adapter} = DeribitAdapter.connect(
  url: "wss://test.deribit.com/ws/api/v2",
  client_id: System.get_env("DERIBIT_CLIENT_ID"),
  client_secret: System.get_env("DERIBIT_CLIENT_SECRET")
)

# Authenticate (if credentials provided)
{:ok, adapter} = DeribitAdapter.authenticate(adapter)

# Use macro-generated methods
{:ok, request} = DeribitAdapter.get_instruments(%{currency: "BTC", kind: "future"})
:ok = WebsockexAdapter.Client.send_message(adapter.client, Jason.encode!(request))
```

## Market Making Workflows

### 1. Initial Market Data Setup

```elixir
# Get available instruments
{:ok, instruments_req} = DeribitAdapter.get_instruments(%{
  currency: "BTC",
  kind: "future",
  expired: false
})

# Subscribe to order book updates
{:ok, adapter} = DeribitAdapter.subscribe(adapter, [
  "book.BTC-PERPETUAL.100ms",
  "ticker.BTC-PERPETUAL.100ms"
])

# Get initial order book snapshot
{:ok, orderbook_req} = DeribitAdapter.get_order_book(%{
  instrument_name: "BTC-PERPETUAL",
  depth: 20
})
```

### 2. Quoting Strategy

```elixir
# Place two-sided quotes
def place_quotes(adapter, instrument, bid_price, ask_price, size) do
  # Place buy order (bid)
  {:ok, buy_req} = DeribitAdapter.buy(%{
    instrument_name: instrument,
    amount: size,
    type: "limit",
    price: bid_price,
    post_only: true,  # Ensure maker fees
    reduce_only: false
  })
  
  # Place sell order (ask)
  {:ok, sell_req} = DeribitAdapter.sell(%{
    instrument_name: instrument,
    amount: size,
    type: "limit", 
    price: ask_price,
    post_only: true,
    reduce_only: false
  })
  
  # Send both orders
  :ok = WebsockexAdapter.Client.send_message(adapter.client, Jason.encode!(buy_req))
  :ok = WebsockexAdapter.Client.send_message(adapter.client, Jason.encode!(sell_req))
end
```

### 3. Order Management

```elixir
# Monitor open orders
{:ok, open_orders_req} = DeribitAdapter.get_open_orders_by_instrument(%{
  instrument_name: "BTC-PERPETUAL"
})

# Edit existing order
{:ok, edit_req} = DeribitAdapter.edit(%{
  order_id: "12345",
  amount: 20,
  price: 50500
})

# Cancel specific order
{:ok, cancel_req} = DeribitAdapter.cancel(%{order_id: "12345"})

# Cancel all orders for instrument
{:ok, cancel_all_req} = DeribitAdapter.cancel_all_by_instrument(%{
  instrument_name: "BTC-PERPETUAL"
})
```

## Options Trading Workflows

### 1. Options Chain Analysis

```elixir
# Get all BTC options
{:ok, options_req} = DeribitAdapter.get_instruments(%{
  currency: "BTC",
  kind: "option",
  expired: false
})

# Get order book for specific option
{:ok, option_book_req} = DeribitAdapter.get_order_book(%{
  instrument_name: "BTC-28JUN24-50000-C",
  depth: 10
})
```

### 2. Options Market Making

```elixir
# Quote options with wider spreads
def quote_option(adapter, option_name, theo_price, edge) do
  bid_price = theo_price - edge
  ask_price = theo_price + edge
  
  {:ok, buy_req} = DeribitAdapter.buy(%{
    instrument_name: option_name,
    amount: 0.1,  # BTC options are in BTC units
    type: "limit",
    price: bid_price,
    post_only: true
  })
  
  {:ok, sell_req} = DeribitAdapter.sell(%{
    instrument_name: option_name,
    amount: 0.1,
    type: "limit",
    price: ask_price,
    post_only: true
  })
  
  # Send orders...
end
```

## Risk Management Patterns

### 1. Position Monitoring

```elixir
# Check account health
{:ok, account_req} = DeribitAdapter.get_account_summary(%{
  currency: "BTC",
  extended: true  # Include Greeks and additional metrics
})

# Get all positions
{:ok, positions_req} = DeribitAdapter.get_positions(%{currency: "BTC"})

# Get specific position
{:ok, position_req} = DeribitAdapter.get_position(%{
  instrument_name: "BTC-PERPETUAL"
})
```

### 2. Emergency Risk Controls

```elixir
# Enable cancel-on-disconnect (critical for market makers)
{:ok, cod_req} = DeribitAdapter.enable_cancel_on_disconnect()
:ok = WebsockexAdapter.Client.send_message(adapter.client, Jason.encode!(cod_req))

# Panic button - cancel everything
def emergency_cancel_all(adapter) do
  currencies = ["BTC", "ETH"]
  
  Enum.each(currencies, fn currency ->
    {:ok, cancel_req} = DeribitAdapter.cancel_all(%{currency: currency})
    WebsockexAdapter.Client.send_message(adapter.client, Jason.encode!(cancel_req))
  end)
end
```

### 3. Heartbeat Management

```elixir
# Set up heartbeat to prevent disconnection
{:ok, heartbeat_req} = DeribitAdapter.set_heartbeat(%{interval: 30})
:ok = WebsockexAdapter.Client.send_message(adapter.client, Jason.encode!(heartbeat_req))

# The adapter will automatically respond to test_request messages
# This prevents order cancellation due to connection timeout
```

## Advanced Patterns

### 1. Bulk Order Operations

```elixir
# Place multiple orders efficiently
def place_ladder_orders(adapter, instrument, base_price, count, spacing, size) do
  buy_orders = for i <- 0..(count-1) do
    price = base_price - (i * spacing)
    {:ok, req} = DeribitAdapter.buy(%{
      instrument_name: instrument,
      amount: size,
      type: "limit",
      price: price,
      post_only: true
    })
    req
  end
  
  # Send all orders
  Enum.each(buy_orders, fn order ->
    WebsockexAdapter.Client.send_message(adapter.client, Jason.encode!(order))
    Process.sleep(50) # Rate limiting
  end)
end
```

### 2. Market Data Aggregation

```elixir
# Get comprehensive market view
def get_market_snapshot(adapter, currency) do
  # Get all instruments
  {:ok, instruments} = DeribitAdapter.get_instruments(%{
    currency: currency,
    expired: false
  })
  
  # Get summary for all instruments
  {:ok, summary} = DeribitAdapter.get_book_summary_by_currency(%{
    currency: currency
  })
  
  # Get index price
  {:ok, index} = DeribitAdapter.get_index_price(%{
    index_name: "#{currency}_usd"
  })
  
  %{
    instruments: instruments,
    summary: summary,
    index: index
  }
end
```

## Error Handling

All macro-generated methods return `{:ok, request}` tuples. Handle errors from the WebSocket responses:

```elixir
# The adapter's handle_message will process errors
# Errors come back as:
# %{"error" => %{"code" => -32602, "message" => "Invalid params"}}

# Authentication errors trigger special handling
# Rate limit errors should implement backoff
# Connection errors trigger automatic reconnection
```

## Performance Considerations

1. **Batch Operations**: Group related requests when possible
2. **Rate Limiting**: Deribit has rate limits - implement appropriate delays
3. **Heartbeat**: Always set up heartbeat for production use
4. **Cancel on Disconnect**: Essential for market makers to avoid orphaned orders
5. **Post-Only Orders**: Use for market making to ensure maker fees

## Testing

Test all workflows against test.deribit.com before production:

```elixir
# Use test environment
{:ok, adapter} = DeribitAdapter.connect(
  url: "wss://test.deribit.com/ws/api/v2"
)

# Test credentials available from Deribit test environment
# Always verify order placement, cancellation, and risk controls
```