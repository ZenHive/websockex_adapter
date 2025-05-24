# Subscriptions

This section describes the subscription channels available through the Deribit WebSocket API. Subscriptions allow you to receive real-time updates instead of polling the API repeatedly.

## Subscription Methods

- [/public/subscribe](#public-subscribe)
- [/public/unsubscribe](#public-unsubscribe)
- [/public/unsubscribe_all](#public-unsubscribe_all)
- [/private/subscribe](#private-subscribe)
- [/private/unsubscribe](#private-unsubscribe)
- [/private/unsubscribe_all](#private-unsubscribe_all)

## Subscription Channels

- [announcements](#announcements)
- [block_rfq.maker.quotes.{currency}](#block_rfq-maker-quotes-currency)
- [block_rfq.maker.{currency}](#block_rfq-maker-currency)
- [block_rfq.taker.{currency}](#block_rfq-taker-currency)
- [block_rfq.trades.{currency}](#block_rfq-trades-currency)
- [block_trade_confirmations](#block_trade_confirmations)
- [book.{instrument_name}.{group}.{depth}.{interval}](#book-instrument_name-group-depth-interval)
- [book.{instrument_name}.{interval}](#book-instrument_name-interval)
- [chart.trades.{instrument_name}.{resolution}](#chart-trades-instrument_name-resolution)
- [deribit_price_index.{index_name}](#deribit_price_index-index_name)
- [deribit_price_ranking.{index_name}](#deribit_price_ranking-index_name)
- [deribit_price_statistics.{index_name}](#deribit_price_statistics-index_name)
- [deribit_volatility_index.{index_name}](#deribit_volatility_index-index_name)
- [estimated_expiration_price.{index_name}](#estimated_expiration_price-index_name)
- [incremental_ticker.{instrument_name}](#incremental_ticker-instrument_name)
- [instrument.state.{kind}.{currency}](#instrument-state-kind-currency)
- [markprice.options.{index_name}](#markprice-options-index_name)
- [perpetual.{instrument_name}.{interval}](#perpetual-instrument_name-interval)
- [platform_state](#platform_state)
- [platform_state.public_methods_state](#platform_state-public_methods_state)
- [quote.{instrument_name}](#quote-instrument_name)
- [rfq.{currency}](#rfq-currency)
- [ticker.{instrument_name}.{interval}](#ticker-instrument_name-interval)
- [trades.{instrument_name}.{interval}](#trades-instrument_name-interval)
- [trades.{kind}.{currency}.{interval}](#trades-kind-currency-interval)
- [user.access_log](#user-access_log)
- [user.changes.{instrument_name}.{interval}](#user-changes-instrument_name-interval)
- [user.changes.{kind}.{currency}.{interval}](#user-changes-kind-currency-interval)
- [user.combo_trades.{instrument_name}.{interval}](#user-combo_trades-instrument_name-interval)
- [user.combo_trades.{kind}.{currency}.{interval}](#user-combo_trades-kind-currency-interval)
- [user.lock](#user-lock)
- [user.mmp_trigger.{index_name}](#user-mmp_trigger-index_name)
- [user.orders.{instrument_name}.raw](#user-orders-instrument_name-raw)
- [user.orders.{instrument_name}.{interval}](#user-orders-instrument_name-interval)
- [user.orders.{kind}.{currency}.raw](#user-orders-kind-currency-raw)
- [user.orders.{kind}.{currency}.{interval}](#user-orders-kind-currency-interval)
- [user.portfolio.{currency}](#user-portfolio-currency)
- [user.trades.{instrument_name}.{interval}](#user-trades-instrument_name-interval)
- [user.trades.{kind}.{currency}.{interval}](#user-trades-kind-currency-interval)

## /public/subscribe

Subscribe to a channel.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 42,
  "method": "public/subscribe",
  "params": {
    "channels": ["ticker.BTC-PERPETUAL.100ms"]
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| channels | array | List of channels to subscribe to |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 42,
  "result": ["ticker.BTC-PERPETUAL.100ms"],
  "usIn": 1535043730126248,
  "usOut": 1535043730126250,
  "usDiff": 2
}
```

## /public/unsubscribe

Unsubscribe from a channel.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 42,
  "method": "public/unsubscribe",
  "params": {
    "channels": ["ticker.BTC-PERPETUAL.100ms"]
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| channels | array | List of channels to unsubscribe from |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 42,
  "result": ["ticker.BTC-PERPETUAL.100ms"],
  "usIn": 1535043730126248,
  "usOut": 1535043730126250,
  "usDiff": 2
}
```

## book.{instrument_name}.{interval}

Order book updates for a specific instrument.

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| instrument_name | string | Instrument name |
| interval | string | Update interval: "100ms" or "raw" |

### Notification

> Example notification:

```json
{
  "jsonrpc": "2.0",
  "method": "subscription",
  "params": {
    "channel": "book.BTC-PERPETUAL.100ms",
    "data": {
      "timestamp": 1554373962454,
      "instrument_name": "BTC-PERPETUAL",
      "change_id": 38476410,
      "bids": [
        ["new", 5000.5, 10],
        ["change", 5000.0, 5]
      ],
      "asks": [
        ["delete", 5001.0, 0]
      ]
    }
  }
}
```

## ticker.{instrument_name}.{interval}

Ticker updates for a specific instrument.

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| instrument_name | string | Instrument name |
| interval | string | Update interval: "100ms" or "raw" |

### Notification

> Example notification:

```json
{
  "jsonrpc": "2.0",
  "method": "subscription",
  "params": {
    "channel": "ticker.BTC-PERPETUAL.100ms",
    "data": {
      "timestamp": 1554373962454,
      "stats": {
        "volume": 0.49355866,
        "price_change": -0.0075,
        "low": 10056.5,
        "high": 10060.0
      },
      "state": "open",
      "settlement_price": 10061.05,
      "open_interest": 52.45271601,
      "min_price": 10056.5,
      "max_price": 10060.0,
      "mark_price": 10058.48,
      "last_price": 10058.5,
      "instrument_name": "BTC-PERPETUAL",
      "index_price": 10050.2,
      "funding_8h": 0.00001212,
      "estimated_delivery_price": 10050.2,
      "current_funding": 0.00001729,
      "best_bid_price": 10057.0,
      "best_bid_amount": 60210.0,
      "best_ask_price": 10058.5,
      "best_ask_amount": 53140.0
    }
  }
}
```

## trades.{instrument_name}.{interval}

Trade updates for a specific instrument.

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| instrument_name | string | Instrument name |
| interval | string | Update interval: "100ms" or "raw" |

### Notification

> Example notification:

```json
{
  "jsonrpc": "2.0",
  "method": "subscription",
  "params": {
    "channel": "trades.BTC-PERPETUAL.100ms",
    "data": [
      {
        "trade_id": "ETH-34066",
        "timestamp": 1550657340846,
        "tick_direction": 2,
        "price": 143.81,
        "mark_price": 143.79,
        "instrument_name": "BTC-PERPETUAL",
        "index_price": 143.73,
        "direction": "buy",
        "amount": 10
      }
    ]
  }
}
```

## user.portfolio.{currency}

Portfolio updates for a specific currency.

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | Currency symbol |

### Notification

> Example notification:

```json
{
  "jsonrpc": "2.0",
  "method": "subscription",
  "params": {
    "channel": "user.portfolio.BTC",
    "data": {
      "total_pl": 0,
      "session_upl": 0,
      "session_rpl": 0,
      "projected_maintenance_margin": 0,
      "projected_initial_margin": 0,
      "projected_delta_total": 0,
      "portfolio_margining_enabled": false,
      "options_vega": 0,
      "options_value": 0,
      "options_theta": 0,
      "options_session_upl": 0,
      "options_session_rpl": 0,
      "options_pl": 0,
      "options_gamma": 0,
      "options_delta": 0,
      "margin_balance": 0.1,
      "maintenance_margin": 0,
      "initial_margin": 0,
      "futures_session_upl": 0,
      "futures_session_rpl": 0,
      "futures_pl": 0,
      "equity": 0.1,
      "delta_total": 0,
      "currency": "BTC",
      "balance": 0.1,
      "available_withdrawal_funds": 0.1,
      "available_funds": 0.1
    }
  }
}
```

## user.trades.{instrument_name}.{interval}

User's trade updates for a specific instrument.

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| instrument_name | string | Instrument name |
| interval | string | Update interval: "100ms" or "raw" |

### Notification

> Example notification:

```json
{
  "jsonrpc": "2.0",
  "method": "subscription",
  "params": {
    "channel": "user.trades.BTC-PERPETUAL.100ms",
    "data": [
      {
        "trade_id": "ETH-34066",
        "timestamp": 1550657340846,
        "tick_direction": 2,
        "price": 143.81,
        "mark_price": 143.79,
        "instrument_name": "BTC-PERPETUAL",
        "index_price": 143.73,
        "fee_currency": "ETH",
        "fee": 0.000139,
        "direction": "buy",
        "amount": 10
      }
    ]
  }
}
```

For detailed information on each channel format, subscription parameters, and notification structure, please refer to the comprehensive DeribitAPI.md document.