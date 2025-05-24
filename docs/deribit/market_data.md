# Market Data

This section describes the market data endpoints of the Deribit API.

## Methods

- [/public/get_book_summary_by_currency](#public-get_book_summary_by_currency)
- [/public/get_book_summary_by_instrument](#public-get_book_summary_by_instrument)
- [/public/get_contract_size](#public-get_contract_size)
- [/public/get_currencies](#public-get_currencies)
- [/public/get_delivery_prices](#public-get_delivery_prices)
- [/public/get_expirations](#public-get_expirations)
- [/public/get_funding_chart_data](#public-get_funding_chart_data)
- [/public/get_funding_rate_history](#public-get_funding_rate_history)
- [/public/get_funding_rate_value](#public-get_funding_rate_value)
- [/public/get_historical_volatility](#public-get_historical_volatility)
- [/public/get_index](#public-get_index)
- [/public/get_index_price](#public-get_index_price)
- [/public/get_index_price_names](#public-get_index_price_names)
- [/public/get_instrument](#public-get_instrument)
- [/public/get_instruments](#public-get_instruments)
- [/public/get_last_settlements_by_currency](#public-get_last_settlements_by_currency)
- [/public/get_last_settlements_by_instrument](#public-get_last_settlements_by_instrument)
- [/public/get_last_trades_by_currency](#public-get_last_trades_by_currency)
- [/public/get_last_trades_by_currency_and_time](#public-get_last_trades_by_currency_and_time)
- [/public/get_last_trades_by_instrument](#public-get_last_trades_by_instrument)
- [/public/get_last_trades_by_instrument_and_time](#public-get_last_trades_by_instrument_and_time)
- [/public/get_mark_price_history](#public-get_mark_price_history)
- [/public/get_order_book](#public-get_order_book)
- [/public/get_order_book_by_instrument_id](#public-get_order_book_by_instrument_id)
- [/public/get_rfqs](#public-get_rfqs)
- [/public/get_supported_index_names](#public-get_supported_index_names)
- [/public/get_trade_volumes](#public-get_trade_volumes)
- [/public/get_tradingview_chart_data](#public-get_tradingview_chart_data)
- [/public/get_volatility_index_data](#public-get_volatility_index_data)
- [/public/ticker](#public-ticker)

## /public/get_book_summary_by_currency

Retrieves the summary information such as open interest, 24h volume, etc. for all instruments for the currency (optionally filtered by kind).

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 42,
  "method": "public/get_book_summary_by_currency",
  "params": {
    "currency": "BTC",
    "kind": "option"
  }
}
```

### Response

> Example response:

Refer to DeribitAPI.md for full method details and response examples.

## /public/get_book_summary_by_instrument

Retrieves the summary information such as open interest, 24h volume, etc. for a specific instrument.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 43,
  "method": "public/get_book_summary_by_instrument",
  "params": {
    "instrument_name": "BTC-PERPETUAL"
  }
}
```

### Response

> Example response:

Refer to DeribitAPI.md for full method details and response examples.

<!-- Continue with other market data methods as necessary -->

## /public/ticker

Retrieve ticker information for an instrument.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 8106,
  "method": "public/ticker",
  "params": {
    "instrument_name": "BTC-PERPETUAL"
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 8106,
  "result": {
    "stats": {
      "volume_usd": 49.94947288,
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
```

For detailed information on each of these methods, including request parameters and response formats, please refer to the comprehensive DeribitAPI.md document.