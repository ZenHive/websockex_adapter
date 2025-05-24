# Market Data

---

## /public/get_book_summary_by_currency

Retrieves summary information (open interest, 24h volume, etc.) for all instruments for the currency (optionally filtered by kind).

### Parameters

| Name     | Type   | Description                                                                        |
| -------- | ------ | ---------------------------------------------------------------------------------- |
| currency | string | The currency symbol. Enum: BTC, ETH, USDC, USDT, EURR                              |
| kind     | string | Instrument kind (optional). Enum: future, option, spot, future_combo, option_combo |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 9344,
  "method": "public/get_book_summary_by_currency",
  "params": {
    "currency": "BTC",
    "kind": "future"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 9344,
  "result": [
    {
      "volume_usd": 0,
      "volume": 0,
      "quote_currency": "USD",
      "price_change": -11.1896349,
      "open_interest": 0,
      "mid_price": null,
      "mark_price": 3579.73,
      "mark_iv": 80,
      "low": null,
      "last": null,
      "instrument_name": "BTC-22FEB19",
      "high": null,
      "estimated_delivery_price": 3579.73,
      "creation_timestamp": 1550230036440,
      "bid_price": null,
      "base_currency": "BTC",
      "ask_price": null
    }
  ]
}
```

### Response Fields

| Name                       | Type    | Description                                  |
| -------------------------- | ------- | -------------------------------------------- |
| id                         | integer | The id sent in the request                   |
| jsonrpc                    | string  | The JSON-RPC version (2.0)                   |
| result                     | array   | List of instrument summaries                 |
| › ask_price                | number  | Current best ask price, null if none         |
| › base_currency            | string  | Base currency                                |
| › bid_price                | number  | Current best bid price, null if none         |
| › creation_timestamp       | integer | Timestamp (ms since Unix epoch)              |
| › current_funding          | number  | Current funding (perpetual only)             |
| › estimated_delivery_price | number  | Estimated delivery price (derivatives only)  |
| › funding_8h               | number  | Funding 8h (perpetual only)                  |
| › high                     | number  | 24h highest trade price                      |
| › instrument_name          | string  | Unique instrument identifier                 |
| › interest_rate            | number  | Interest rate (options only)                 |
| › last                     | number  | Latest trade price, null if none             |
| › low                      | number  | 24h lowest trade price, null if none         |
| › mark_iv                  | number  | Implied volatility for mark price (option)   |
| › mark_price               | number  | Current market price                         |
| › mid_price                | number  | Average of best bid/ask, null if none        |
| › open_interest            | number  | Outstanding contracts (see docs for units)   |
| › price_change             | number  | 24h price change (%)                         |
| › quote_currency           | string  | Quote currency                               |
| › underlying_index         | string  | Underlying future or 'index_price' (options) |
| › underlying_price         | number  | Underlying price (options only)              |
| › volume                   | number  | 24h traded volume (base currency)            |
| › volume_notional          | number  | Volume in quote currency (futures/spots)     |
| › volume_usd               | number  | Volume in USD                                |

---

## /public/get_book_summary_by_instrument

Retrieves summary information (open interest, 24h volume, etc.) for a specific instrument.

### Parameters

| Name            | Type   | Description     |
| --------------- | ------ | --------------- |
| instrument_name | string | Instrument name |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 3659,
  "method": "public/get_book_summary_by_instrument",
  "params": {
    "instrument_name": "ETH-22FEB19-140-P"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 3659,
  "result": [
    {
      "volume": 0.55,
      "underlying_price": 121.38,
      "underlying_index": "index_price",
      "quote_currency": "USD",
      "price_change": -26.7793594,
      "open_interest": 0.55,
      "mid_price": 0.2444,
      "mark_price": 0.179112,
      "mark_iv": 80,
      "low": 0.34,
      "last": 0.34,
      "interest_rate": 0.207,
      "instrument_name": "ETH-22FEB19-140-P",
      "high": 0.34,
      "creation_timestamp": 1550227952163,
      "bid_price": 0.1488,
      "base_currency": "ETH",
      "ask_price": 0.34
    }
  ]
}
```

### Response Fields

| Name                       | Type    | Description                                  |
| -------------------------- | ------- | -------------------------------------------- |
| id                         | integer | The id sent in the request                   |
| jsonrpc                    | string  | The JSON-RPC version (2.0)                   |
| result                     | array   | List of instrument summaries                 |
| › ask_price                | number  | Current best ask price, null if none         |
| › base_currency            | string  | Base currency                                |
| › bid_price                | number  | Current best bid price, null if none         |
| › creation_timestamp       | integer | Timestamp (ms since Unix epoch)              |
| › current_funding          | number  | Current funding (perpetual only)             |
| › estimated_delivery_price | number  | Estimated delivery price (derivatives only)  |
| › funding_8h               | number  | Funding 8h (perpetual only)                  |
| › high                     | number  | 24h highest trade price                      |
| › instrument_name          | string  | Unique instrument identifier                 |
| › interest_rate            | number  | Interest rate (options only)                 |
| › last                     | number  | Latest trade price, null if none             |
| › low                      | number  | 24h lowest trade price, null if none         |
| › mark_iv                  | number  | Implied volatility for mark price (option)   |
| › mark_price               | number  | Current market price                         |
| › mid_price                | number  | Average of best bid/ask, null if none        |
| › open_interest            | number  | Outstanding contracts (see docs for units)   |
| › price_change             | number  | 24h price change (%)                         |
| › quote_currency           | string  | Quote currency                               |
| › underlying_index         | string  | Underlying future or 'index_price' (options) |
| › underlying_price         | number  | Underlying price (options only)              |
| › volume                   | number  | 24h traded volume (base currency)            |
| › volume_notional          | number  | Volume in quote currency (futures/spots)     |
| › volume_usd               | number  | Volume in USD                                |

---

## /public/get_contract_size

Retrieves contract size of the provided instrument.

### Parameters

| Name            | Type   | Description     |
| --------------- | ------ | --------------- |
| instrument_name | string | Instrument name |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "public/get_contract_size",
  "id": 42,
  "params": {
    "instrument_name": "BTC-PERPETUAL"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "result": {
    "contract_size": 10
  }
}
```

### Response Fields

| Name            | Type    | Description                                                                |
| --------------- | ------- | -------------------------------------------------------------------------- |
| id              | integer | The id sent in the request                                                 |
| jsonrpc         | string  | The JSON-RPC version (2.0)                                                 |
| result          | object  |                                                                            |
| › contract_size | integer | Contract size (futures in USD, options in base currency of the instrument) |

---

## /public/get_currencies

Retrieves all cryptocurrencies supported by the API.

### Parameters

_None_

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 7538,
  "method": "public/get_currencies",
  "params": {}
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 7538,
  "result": [
    {
      "coin_type": "ETHER",
      "currency": "ETH",
      "currency_long": "Ethereum",
      "fee_precision": 4,
      "min_confirmations": 1,
      "min_withdrawal_fee": 0.0001,
      "withdrawal_fee": 0.0006,
      "withdrawal_priorities": []
    }
  ]
}
```

### Response Fields

| Name                       | Type    | Description                                  |
| -------------------------- | ------- | -------------------------------------------- |
| id                         | integer | The id sent in the request                   |
| jsonrpc                    | string  | The JSON-RPC version (2.0)                   |
| result                     | array   | List of supported currencies                 |
| › coin_type                | string  | The type of the currency                     |
| › currency                 | string  | Abbreviation used elsewhere in the API       |
| › currency_long            | string  | Full name for the currency                   |
| › fee_precision            | integer | Fee precision                                |
| › in_cross_collateral_pool | boolean | True if part of cross collateral pool        |
| › min_confirmations        | integer | Minimum blockchain confirmations for deposit |
| › min_withdrawal_fee       | number  | Minimum transaction fee for withdrawals      |
| › withdrawal_fee           | number  | Total transaction fee for withdrawals        |
| › withdrawal_priorities    | array   | Withdrawal priority objects                  |
| ›› name                    | string  | Priority name                                |
| ›› value                   | number  | Priority value                               |

---

## /public/get_delivery_prices

Retrieves delivery prices for the given index.

### Parameters

| Name       | Type    | Description                                     |
| ---------- | ------- | ----------------------------------------------- |
| index_name | string  | Index identifier (e.g., btc_usd, eth_usd, etc.) |
| offset     | integer | Offset for pagination (default: 0)              |
| count      | integer | Number of requested items (default: 10)         |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 3601,
  "method": "public/get_delivery_prices",
  "params": {
    "index_name": "btc_usd",
    "offset": 0,
    "count": 5
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 3601,
  "result": {
    "data": [{ "date": "2020-01-02", "delivery_price": 7131.21 }],
    "records_total": 58
  }
}
```

### Response Fields

| Name              | Type    | Description                         |
| ----------------- | ------- | ----------------------------------- |
| id                | integer | The id sent in the request          |
| jsonrpc           | string  | The JSON-RPC version (2.0)          |
| result            | object  |                                     |
| › data            | array   | List of delivery price objects      |
| ›› date           | string  | Event date (YYYY-MM-DD)             |
| ›› delivery_price | number  | Settlement price for the instrument |
| › records_total   | number  | Total available delivery prices     |

---

## /public/get_expirations

Retrieves expirations for instruments.

### Parameters

| Name          | Type   | Description                                   |
| ------------- | ------ | --------------------------------------------- |
| currency      | string | Currency symbol or "any"/"grouped"            |
| kind          | string | Instrument kind: "future", "option", or "any" |
| currency_pair | string | Currency pair symbol (optional)               |

### JSON-RPC Request Example

```json
{
  "method": "public/get_expirations",
  "params": {
    "currency": "any",
    "kind": "any"
  },
  "jsonrpc": "2.0",
  "id": 1
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "result": {
    "future": ["21SEP24", "22SEP24", "PERPETUAL"],
    "option": ["21SEP24", "22SEP24", "23SEP24"]
  }
}
```

### Response Fields

| Name    | Type    | Description                                 |
| ------- | ------- | ------------------------------------------- |
| id      | integer | The id sent in the request                  |
| jsonrpc | string  | The JSON-RPC version (2.0)                  |
| result  | object  | Map of currency/kind to list of expirations |

---

## /public/get_funding_chart_data

Retrieve the latest PERPETUAL funding chart points within a given time period.

### Parameters

| Name            | Type   | Description                 |
| --------------- | ------ | --------------------------- |
| instrument_name | string | Instrument name             |
| length          | string | Time period: 8h, 24h, or 1m |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "public/get_funding_chart_data",
  "id": 42,
  "params": {
    "instrument_name": "BTC-PERPETUAL",
    "length": "8h"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "result": {
    "current_interest": 0.0050006706,
    "data": [
      {
        "index_price": 8247.27,
        "interest_8h": 0.0049995114,
        "timestamp": 1536569522277
      }
    ],
    "interest_8h": 0.0040080897
  }
}
```

### Response Fields

| Name               | Type    | Description                     |
| ------------------ | ------- | ------------------------------- |
| id                 | integer | The id sent in the request      |
| jsonrpc            | string  | The JSON-RPC version (2.0)      |
| result             | object  |                                 |
| › current_interest | number  | Current interest                |
| › data             | array   | List of funding chart points    |
| ›› index_price     | number  | Current index price             |
| ›› interest_8h     | number  | Historical interest 8h value    |
| ›› timestamp       | integer | Timestamp (ms since Unix epoch) |
| › interest_8h      | number  | Current interest 8h             |

---

## /public/get_funding_rate_history

Retrieves hourly historical interest rate for requested PERPETUAL instrument.

### Parameters

| Name            | Type    | Description                                 |
| --------------- | ------- | ------------------------------------------- |
| instrument_name | string  | Instrument name                             |
| start_timestamp | integer | Earliest timestamp (ms since Unix epoch)    |
| end_timestamp   | integer | Most recent timestamp (ms since Unix epoch) |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 7617,
  "method": "public/get_funding_rate_history",
  "params": {
    "instrument_name": "BTC-PERPETUAL",
    "start_timestamp": 1569888000000,
    "end_timestamp": 1569902400000
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 7617,
  "result": [
    {
      "timestamp": 1569891600000,
      "index_price": 8222.87,
      "prev_index_price": 8305.72,
      "interest_8h": -0.00009234,
      "interest_1h": -4.739e-7
    }
  ]
}
```

### Response Fields

| Name               | Type    | Description                          |
| ------------------ | ------- | ------------------------------------ |
| id                 | integer | The id sent in the request           |
| jsonrpc            | string  | The JSON-RPC version (2.0)           |
| result             | array   | List of funding rate history objects |
| › index_price      | number  | Price in base currency               |
| › interest_1h      | float   | 1 hour interest rate                 |
| › interest_8h      | float   | 8 hour interest rate                 |
| › prev_index_price | number  | Previous index price                 |
| › timestamp        | integer | Timestamp (ms since Unix epoch)      |

---

## /public/get_funding_rate_value

Retrieves interest rate value for requested period (PERPETUAL instruments only).

### Parameters

| Name            | Type    | Description                                 |
| --------------- | ------- | ------------------------------------------- |
| instrument_name | string  | Instrument name                             |
| start_timestamp | integer | Earliest timestamp (ms since Unix epoch)    |
| end_timestamp   | integer | Most recent timestamp (ms since Unix epoch) |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 7617,
  "method": "public/get_funding_rate_value",
  "params": {
    "instrument_name": "BTC-PERPETUAL",
    "start_timestamp": 1569888000000,
    "end_timestamp": 1569974400000
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 7617,
  "result": -0.00025056853702101664
}
```

### Response Fields

| Name    | Type    | Description                |
| ------- | ------- | -------------------------- |
| id      | integer | The id sent in the request |
| jsonrpc | string  | The JSON-RPC version (2.0) |
| result  | float   | Interest rate value        |

---

## /public/get_historical_volatility

Provides information about historical volatility for a given cryptocurrency.

### Parameters

| Name     | Type   | Description         |
| -------- | ------ | ------------------- |
| currency | string | The currency symbol |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 8387,
  "method": "public/get_historical_volatility",
  "params": {
    "currency": "BTC"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 8387,
  "result": [
    [1549720800000, 14.747743607344217],
    [1549724400000, 14.74257778551467]
  ]
}
```

### Response Fields

| Name    | Type                | Description                |
| ------- | ------------------- | -------------------------- |
| id      | integer             | The id sent in the request |
| jsonrpc | string              | The JSON-RPC version (2.0) |
| result  | array of [int, num] | [timestamp, value] pairs   |

---

## /public/get_index

Retrieves the current index price for the selected currency.

### Parameters

| Name     | Type   | Description         |
| -------- | ------ | ------------------- |
| currency | string | The currency symbol |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "public/get_index",
  "id": 42,
  "params": {
    "currency": "BTC"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "result": {
    "BTC": 11628.81,
    "edp": 11628.81
  }
}
```

### Response Fields

| Name    | Type    | Description                               |
| ------- | ------- | ----------------------------------------- |
| id      | integer | The id sent in the request                |
| jsonrpc | string  | The JSON-RPC version (2.0)                |
| result  | object  |                                           |
| › BTC   | number  | Current index price for BTC-USD           |
| › ETH   | number  | Current index price for ETH-USD           |
| › edp   | number  | Estimated delivery price for the currency |

---

## /public/get_index_price

Retrieves the current index price value for a given index name.

### Parameters

| Name       | Type   | Description                                     |
| ---------- | ------ | ----------------------------------------------- |
| index_name | string | Index identifier (e.g., btc_usd, eth_usd, etc.) |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "public/get_index_price",
  "id": 42,
  "params": {
    "index_name": "ada_usd"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "result": {
    "estimated_delivery_price": 11628.81,
    "index_price": 11628.81
  }
}
```

### Response Fields

| Name                       | Type    | Description                             |
| -------------------------- | ------- | --------------------------------------- |
| id                         | integer | The id sent in the request              |
| jsonrpc                    | string  | The JSON-RPC version (2.0)              |
| result                     | object  |                                         |
| › estimated_delivery_price | number  | Estimated delivery price for the market |
| › index_price              | number  | Value of requested index                |

---

## /public/get_index_price_names

Retrieves the identifiers of all supported Price Indexes.

### Parameters

_None_

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "public/get_index_price_names",
  "id": 42
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 7617,
  "result": ["btc_usd", "eth_usd", "btc_usdc", "eth_usdc"]
}
```

### Response Fields

| Name    | Type          | Description                |
| ------- | ------------- | -------------------------- |
| id      | integer       | The id sent in the request |
| jsonrpc | string        | The JSON-RPC version (2.0) |
| result  | array<string> | List of index price names  |

---

## /public/get_instrument

Retrieves information about an instrument.

### Parameters

| Name            | Type   | Description     |
| --------------- | ------ | --------------- |
| instrument_name | string | Instrument name |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "public/get_instrument",
  "id": 2,
  "params": {
    "instrument_name": "BTC-13JAN23-16000-P"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "tick_size": 0.0005,
    "instrument_name": "BTC-13JAN23-16000-P",
    "kind": "option",
    "base_currency": "BTC"
  }
}
```

### Response Fields

| Name              | Type    | Description                       |
| ----------------- | ------- | --------------------------------- |
| id                | integer | The id sent in the request        |
| jsonrpc           | string  | The JSON-RPC version (2.0)        |
| result            | object  | Instrument details                |
| › instrument_name | string  | Unique instrument identifier      |
| › kind            | string  | Instrument kind                   |
| › base_currency   | string  | Underlying currency               |
| › tick_size       | number  | Minimum price change              |
| ...               | ...     | (See API for full list of fields) |

---

## /public/get_instruments

Retrieves available trading instruments (active or expired).

### Parameters

| Name     | Type    | Description                         |
| -------- | ------- | ----------------------------------- |
| currency | string  | Currency symbol or "any" for all    |
| kind     | string  | Instrument kind (optional)          |
| expired  | boolean | Show expired instruments (optional) |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "public/get_instruments",
  "id": 1,
  "params": {
    "currency": "BTC",
    "kind": "future"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": [
    {
      "instrument_name": "BTC-29SEP23",
      "kind": "future",
      "base_currency": "BTC"
    }
  ]
}
```

### Response Fields

| Name              | Type    | Description                       |
| ----------------- | ------- | --------------------------------- |
| id                | integer | The id sent in the request        |
| jsonrpc           | string  | The JSON-RPC version (2.0)        |
| result            | array   | List of instrument objects        |
| › instrument_name | string  | Unique instrument identifier      |
| › kind            | string  | Instrument kind                   |
| › base_currency   | string  | Underlying currency               |
| ...               | ...     | (See API for full list of fields) |

---

## /public/get_last_settlements_by_currency

Retrieves historical settlement, delivery, and bankruptcy events for all instruments within a given currency.

### Parameters

| Name                   | Type    | Description                                  |
| ---------------------- | ------- | -------------------------------------------- |
| currency               | string  | Currency symbol                              |
| type                   | string  | Settlement type (optional)                   |
| count                  | integer | Number of items (optional)                   |
| continuation           | string  | Continuation token for pagination (optional) |
| search_start_timestamp | integer | Latest timestamp to return from (optional)   |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 4497,
  "method": "public/get_last_settlements_by_currency",
  "params": {
    "currency": "BTC",
    "type": "delivery",
    "count": 2
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 4497,
  "result": {
    "settlements": [
      {
        "type": "delivery",
        "timestamp": 1550242800013,
        "instrument_name": "BTC-15FEB19-4000-P"
      }
    ],
    "continuation": "token"
  }
}
```

### Response Fields

| Name           | Type    | Description                       |
| -------------- | ------- | --------------------------------- |
| id             | integer | The id sent in the request        |
| jsonrpc        | string  | The JSON-RPC version (2.0)        |
| result         | object  |                                   |
| › settlements  | array   | List of settlement objects        |
| › continuation | string  | Continuation token for pagination |
| ...            | ...     | (See API for full list of fields) |

---

## /public/get_last_settlements_by_instrument

Retrieves historical settlement, delivery, and bankruptcy events filtered by instrument name.

### Parameters

| Name                   | Type    | Description                                  |
| ---------------------- | ------- | -------------------------------------------- |
| instrument_name        | string  | Instrument name                              |
| type                   | string  | Settlement type (optional)                   |
| count                  | integer | Number of items (optional)                   |
| continuation           | string  | Continuation token for pagination (optional) |
| search_start_timestamp | integer | Latest timestamp to return from (optional)   |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 5482,
  "method": "public/get_last_settlements_by_instrument",
  "params": {
    "instrument_name": "BTC-22FEB19",
    "type": "settlement",
    "count": 1
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 5482,
  "result": {
    "settlements": [
      {
        "type": "settlement",
        "timestamp": 1550502000023,
        "instrument_name": "BTC-22FEB19"
      }
    ],
    "continuation": "token"
  }
}
```

### Response Fields

| Name           | Type    | Description                       |
| -------------- | ------- | --------------------------------- |
| id             | integer | The id sent in the request        |
| jsonrpc        | string  | The JSON-RPC version (2.0)        |
| result         | object  |                                   |
| › settlements  | array   | List of settlement objects        |
| › continuation | string  | Continuation token for pagination |
| ...            | ...     | (See API for full list of fields) |

---

## /public/get_last_trades_by_currency

Retrieve the latest trades for instruments in a specific currency symbol.

### Parameters

| Name            | Type    | Description                            |
| --------------- | ------- | -------------------------------------- |
| currency        | string  | Currency symbol                        |
| kind            | string  | Instrument kind (optional)             |
| start_id        | string  | ID of first trade to return (optional) |
| end_id          | string  | ID of last trade to return (optional)  |
| start_timestamp | integer | Earliest timestamp (optional)          |
| end_timestamp   | integer | Most recent timestamp (optional)       |
| count           | integer | Number of items (optional)             |
| sorting         | string  | Sorting direction (optional)           |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 9290,
  "method": "public/get_last_trades_by_currency",
  "params": {
    "currency": "BTC",
    "count": 1
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 9290,
  "result": {
    "trades": [
      {
        "trade_seq": 36798,
        "trade_id": "277976",
        "timestamp": 1590476708320,
        "price": 8767.08
      }
    ],
    "has_more": true
  }
}
```

### Response Fields

| Name       | Type    | Description                       |
| ---------- | ------- | --------------------------------- |
| id         | integer | The id sent in the request        |
| jsonrpc    | string  | The JSON-RPC version (2.0)        |
| result     | object  |                                   |
| › trades   | array   | List of trade objects             |
| › has_more | boolean | More trades available             |
| ...        | ...     | (See API for full list of fields) |

---

## /public/get_last_trades_by_currency_and_time

Retrieve the latest trades for instruments in a specific currency symbol and time range.

### Parameters

| Name            | Type    | Description                                 |
| --------------- | ------- | ------------------------------------------- |
| currency        | string  | Currency symbol                             |
| kind            | string  | Instrument kind (optional)                  |
| start_timestamp | integer | Earliest timestamp (ms since Unix epoch)    |
| end_timestamp   | integer | Most recent timestamp (ms since Unix epoch) |
| count           | integer | Number of items (optional)                  |
| sorting         | string  | Sorting direction (optional)                |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 1469,
  "method": "public/get_last_trades_by_currency_and_time",
  "params": {
    "currency": "BTC",
    "start_timestamp": 1590470022768,
    "end_timestamp": 1590480022768,
    "count": 1
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 1469,
  "result": {
    "trades": [
      {
        "trade_seq": 3471,
        "trade_id": "48077291",
        "timestamp": 1590470616101,
        "price": 0.032
      }
    ],
    "has_more": true
  }
}
```

### Response Fields

| Name       | Type    | Description                       |
| ---------- | ------- | --------------------------------- |
| id         | integer | The id sent in the request        |
| jsonrpc    | string  | The JSON-RPC version (2.0)        |
| result     | object  |                                   |
| › trades   | array   | List of trade objects             |
| › has_more | boolean | More trades available             |
| ...        | ...     | (See API for full list of fields) |

---

## /public/get_last_trades_by_instrument

Retrieve the latest trades for a specific instrument.

### Parameters

| Name            | Type    | Description                               |
| --------------- | ------- | ----------------------------------------- |
| instrument_name | string  | Instrument name                           |
| start_seq       | integer | Sequence number of first trade (optional) |
| end_seq         | integer | Sequence number of last trade (optional)  |
| start_timestamp | integer | Earliest timestamp (optional)             |
| end_timestamp   | integer | Most recent timestamp (optional)          |
| count           | integer | Number of items (optional)                |
| sorting         | string  | Sorting direction (optional)              |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 9267,
  "method": "public/get_last_trades_by_instrument",
  "params": {
    "instrument_name": "BTC-PERPETUAL",
    "count": 1
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 9267,
  "result": {
    "trades": [
      {
        "trade_seq": 36798,
        "trade_id": "277976",
        "timestamp": 1590476708320,
        "price": 8767.08
      }
    ],
    "has_more": true
  }
}
```

### Response Fields

| Name       | Type    | Description                       |
| ---------- | ------- | --------------------------------- |
| id         | integer | The id sent in the request        |
| jsonrpc    | string  | The JSON-RPC version (2.0)        |
| result     | object  |                                   |
| › trades   | array   | List of trade objects             |
| › has_more | boolean | More trades available             |
| ...        | ...     | (See API for full list of fields) |

---

## /public/get_last_trades_by_instrument_and_time

Retrieve the latest trades for a specific instrument and time range.

### Parameters

| Name            | Type    | Description                                 |
| --------------- | ------- | ------------------------------------------- |
| instrument_name | string  | Instrument name                             |
| start_timestamp | integer | Earliest timestamp (ms since Unix epoch)    |
| end_timestamp   | integer | Most recent timestamp (ms since Unix epoch) |
| count           | integer | Number of items (optional)                  |
| sorting         | string  | Sorting direction (optional)                |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 3983,
  "method": "public/get_last_trades_by_instrument_and_time",
  "params": {
    "instrument_name": "ETH-PERPETUAL",
    "end_timestamp": 1590480022768,
    "count": 1
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 3983,
  "result": {
    "trades": [
      {
        "trade_seq": 1966031,
        "trade_id": "ETH-2696055",
        "timestamp": 1590479408216,
        "price": 203.6
      }
    ],
    "has_more": true
  }
}
```

### Response Fields

| Name       | Type    | Description                       |
| ---------- | ------- | --------------------------------- |
| id         | integer | The id sent in the request        |
| jsonrpc    | string  | The JSON-RPC version (2.0)        |
| result     | object  |                                   |
| › trades   | array   | List of trade objects             |
| › has_more | boolean | More trades available             |
| ...        | ...     | (See API for full list of fields) |

---

## /public/get_mark_price_history

Public request for 5min history of mark price values for the instrument.

### Parameters

| Name            | Type    | Description                                 |
| --------------- | ------- | ------------------------------------------- |
| instrument_name | string  | Instrument name                             |
| start_timestamp | integer | Earliest timestamp (ms since Unix epoch)    |
| end_timestamp   | integer | Most recent timestamp (ms since Unix epoch) |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "public/get_mark_price_history",
  "params": {
    "instrument_name": "BTC-25JUN21-50000-C",
    "start_timestamp": 1609376800000,
    "end_timestamp": 1609376810000
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 25,
  "result": [
    [1608142381229, 0.5165791606037885],
    [1608142380231, 0.5165737855432504]
  ]
}
```

### Response Fields

| Name    | Type                | Description                   |
| ------- | ------------------- | ----------------------------- |
| id      | integer             | The id sent in the request    |
| jsonrpc | string              | The JSON-RPC version (2.0)    |
| result  | array of [int, num] | [timestamp, mark price] pairs |

---

## /public/get_order_book

Retrieves the order book and other market values for a given instrument.

### Parameters

| Name            | Type    | Description                                |
| --------------- | ------- | ------------------------------------------ |
| instrument_name | string  | Instrument name                            |
| depth           | integer | Number of entries for bids/asks (optional) |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 8772,
  "method": "public/get_order_book",
  "params": {
    "instrument_name": "BTC-PERPETUAL",
    "depth": 5
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 8772,
  "result": {
    "timestamp": 1550757626706,
    "bids": [[3955.75, 30.0]],
    "asks": [],
    "instrument_name": "BTC-PERPETUAL"
  }
}
```

### Response Fields

| Name              | Type    | Description                       |
| ----------------- | ------- | --------------------------------- |
| id                | integer | The id sent in the request        |
| jsonrpc           | string  | The JSON-RPC version (2.0)        |
| result            | object  |                                   |
| › bids            | array   | List of [price, amount] for bids  |
| › asks            | array   | List of [price, amount] for asks  |
| › instrument_name | string  | Unique instrument identifier      |
| ...               | ...     | (See API for full list of fields) |

---

## /public/get_order_book_by_instrument_id

Retrieves the order book and other market values for a given instrument ID.

### Parameters

| Name          | Type    | Description                                |
| ------------- | ------- | ------------------------------------------ |
| instrument_id | integer | Instrument ID                              |
| depth         | integer | Number of entries for bids/asks (optional) |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 42,
  "method": "public/get_order_book_by_instrument_id",
  "params": {
    "instrument_id": 42,
    "depth": 1
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 8772,
  "result": {
    "timestamp": 1550757626706,
    "bids": [[3955.75, 30.0]],
    "asks": [],
    "instrument_name": "BTC-PERPETUAL"
  }
}
```

### Response Fields

| Name              | Type    | Description                       |
| ----------------- | ------- | --------------------------------- |
| id                | integer | The id sent in the request        |
| jsonrpc           | string  | The JSON-RPC version (2.0)        |
| result            | object  |                                   |
| › bids            | array   | List of [price, amount] for bids  |
| › asks            | array   | List of [price, amount] for asks  |
| › instrument_name | string  | Unique instrument identifier      |
| ...               | ...     | (See API for full list of fields) |

---

## /public/get_rfqs

Retrieve active RFQs for instruments in a given currency.

### Parameters

| Name     | Type   | Description                |
| -------- | ------ | -------------------------- |
| currency | string | Currency symbol            |
| kind     | string | Instrument kind (optional) |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "public/get_rfqs",
  "params": {
    "currency": "BTC",
    "kind": "future"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": [
    {
      "traded_volume": 0,
      "amount": 10,
      "side": "buy",
      "instrument_name": "BTC-PERPETUAL"
    }
  ]
}
```

### Response Fields

| Name              | Type    | Description                       |
| ----------------- | ------- | --------------------------------- |
| id                | integer | The id sent in the request        |
| jsonrpc           | string  | The JSON-RPC version (2.0)        |
| result            | array   | List of RFQ objects               |
| › instrument_name | string  | Unique instrument identifier      |
| › amount          | number  | Requested order size              |
| › side            | string  | Side: buy or sell                 |
| ...               | ...     | (See API for full list of fields) |

---

## /public/get_supported_index_names

Retrieves the identifiers of all supported Price Indexes.

### Parameters

| Name | Type   | Description                    |
| ---- | ------ | ------------------------------ |
| type | string | Type of price index (optional) |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "method": "public/get_supported_index_names",
  "id": 42,
  "params": {
    "type": "all"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 25718,
  "result": ["btc_eth", "btc_usdc", "eth_usdc"]
}
```

### Response Fields

| Name    | Type          | Description                   |
| ------- | ------------- | ----------------------------- |
| id      | integer       | The id sent in the request    |
| jsonrpc | string        | The JSON-RPC version (2.0)    |
| result  | array<string> | List of supported index names |

---

## /public/get_trade_volumes

Retrieves aggregated 24h trade volumes for different instrument types and currencies.

### Parameters

| Name     | Type    | Description                       |
| -------- | ------- | --------------------------------- |
| extended | boolean | Request extended stats (optional) |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 6387,
  "method": "public/get_trade_volumes"
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 6387,
  "result": [
    {
      "puts_volume": 48,
      "futures_volume": 6.25,
      "currency": "BTC",
      "calls_volume": 145,
      "spot_volume": 11.1
    }
  ]
}
```

### Response Fields

| Name             | Type    | Description                       |
| ---------------- | ------- | --------------------------------- |
| id               | integer | The id sent in the request        |
| jsonrpc          | string  | The JSON-RPC version (2.0)        |
| result           | array   | List of trade volume objects      |
| › currency       | string  | Currency                          |
| › calls_volume   | number  | 24h trade volume for call options |
| › puts_volume    | number  | 24h trade volume for put options  |
| › futures_volume | number  | 24h trade volume for futures      |
| › spot_volume    | number  | 24h trade for spot                |
| ...              | ...     | (See API for full list of fields) |

---

## /public/get_tradingview_chart_data

Publicly available market data used to generate a TradingView candle chart.

### Parameters

| Name            | Type    | Description                                 |
| --------------- | ------- | ------------------------------------------- |
| instrument_name | string  | Instrument name                             |
| start_timestamp | integer | Earliest timestamp (ms since Unix epoch)    |
| end_timestamp   | integer | Most recent timestamp (ms since Unix epoch) |
| resolution      | string  | Chart bars resolution (minutes or '1D')     |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 833,
  "method": "public/get_tradingview_chart_data",
  "params": {
    "instrument_name": "BTC-5APR19",
    "start_timestamp": 1554373800000,
    "end_timestamp": 1554376800000,
    "resolution": "30"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 833,
  "result": {
    "volume": [19.0, 20.1],
    "cost": [19000.0, 23400.0],
    "ticks": [1554373800000, 1554375600000],
    "status": "ok",
    "open": [4963.42, 4986.29],
    "low": [4728.94, 4726.6],
    "high": [5185.45, 5250.87],
    "close": [5052.95, 5013.59]
  }
}
```

### Response Fields

| Name     | Type    | Description                            |
| -------- | ------- | -------------------------------------- |
| id       | integer | The id sent in the request             |
| jsonrpc  | string  | The JSON-RPC version (2.0)             |
| result   | object  |                                        |
| › volume | array   | List of volume bars (base currency)    |
| › cost   | array   | List of cost bars (quote currency)     |
| › ticks  | array   | Time axis values (ms since Unix epoch) |
| › status | string  | Status of the query                    |
| › open   | array   | List of open prices                    |
| › low    | array   | List of low prices                     |
| › high   | array   | List of high prices                    |
| › close  | array   | List of close prices                   |

---

## /public/get_volatility_index_data

Public market data request for volatility index candles.

### Parameters

| Name            | Type    | Description                                 |
| --------------- | ------- | ------------------------------------------- |
| currency        | string  | The currency symbol                         |
| start_timestamp | integer | Earliest timestamp (ms since Unix epoch)    |
| end_timestamp   | integer | Most recent timestamp (ms since Unix epoch) |
| resolution      | string  | Time resolution (seconds or '1D')           |

### JSON-RPC Request Example

```json
{
  "jsonrpc": "2.0",
  "id": 833,
  "method": "public/get_volatility_index_data",
  "params": {
    "currency": "BTC",
    "start_timestamp": 1599373800000,
    "end_timestamp": 1599376800000,
    "resolution": "60"
  }
}
```

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": {
    "data": [
      [1598019300000, 0.210084879, 0.212860821, 0.210084879, 0.212860821]
    ],
    "continuation": null
  }
}
```

### Response Fields

| Name           | Type    | Description                                             |
| -------------- | ------- | ------------------------------------------------------- |
| id             | integer | The id sent in the request                              |
| jsonrpc        | string  | The JSON-RPC version (2.0)                              |
| result         | object  |                                                         |
| › data         | array   | Candles as array of [timestamp, open, high, low, close] |
| › continuation | integer | Continuation for pagination (nullable)                  |

---

## /public/ticker

Get ticker for an instrument.

### Parameters

| Name            | Type   | Description     |
| --------------- | ------ | --------------- |
| instrument_name | string | Instrument name |

### JSON-RPC Request Example

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

### JSON-RPC Response Example

```json
{
  "jsonrpc": "2.0",
  "id": 8106,
  "result": {
    "best_ask_amount": 53040,
    "best_ask_price": 36290,
    "best_bid_amount": 4600,
    "best_bid_price": 36289.5,
    "current_funding": 0,
    "estimated_delivery_price": 36297.02,
    "funding_8h": 0.00002203,
    "index_price": 36297.02,
    "instrument_name": "BTC-PERPETUAL",
    "interest_value": 1.7362511643080387,
    "last_price": 36289.5,
    "mark_price": 36288.31,
    "max_price": 36833.4,
    "min_price": 35744.73,
    "open_interest": 502231260,
    "settlement_price": 36169.49,
    "state": "open",
    "stats": {
      "high": 36824.5,
      "low": 35213.5,
      "price_change": 0.2362,
      "volume": 7831.26548117,
      "volume_usd": 282615600
    },
    "timestamp": 1623059681955
  }
}
```

### Response Fields

| Name              | Type    | Description                       |
| ----------------- | ------- | --------------------------------- |
| id                | integer | The id sent in the request        |
| jsonrpc           | string  | The JSON-RPC version (2.0)        |
| result            | object  |                                   |
| › instrument_name | string  | Unique instrument identifier      |
| › best_ask_price  | number  | Current best ask price            |
| › best_bid_price  | number  | Current best bid price            |
| › last_price      | number  | Last trade price                  |
| › mark_price      | number  | Mark price                        |
| › open_interest   | number  | Outstanding contracts             |
| › stats           | object  | 24h stats                         |
| › timestamp       | integer | Timestamp (ms since Unix epoch)   |
| ...               | ...     | (See API for full list of fields) |
