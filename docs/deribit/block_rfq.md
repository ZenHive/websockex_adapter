# Block RFQ

This section describes the Block Request for Quote (RFQ) endpoints of the Deribit API. Block RFQs are used for institutional-sized trades.

## Methods

- [/public/get_block_rfq_trades](#public-get_block_rfq_trades)
- [/private/add_block_rfq_quote](#private-add_block_rfq_quote)
- [/private/cancel_all_block_rfq_quotes](#private-cancel_all_block_rfq_quotes)
- [/private/cancel_block_rfq](#private-cancel_block_rfq)
- [/private/cancel_block_rfq_quote](#private-cancel_block_rfq_quote)
- [/private/create_block_rfq](#private-create_block_rfq)
- [/private/edit_block_rfq_quote](#private-edit_block_rfq_quote)
- [/private/get_block_rfq_makers](#private-get_block_rfq_makers)
- [/private/get_block_rfq_quotes](#private-get_block_rfq_quotes)
- [/private/get_block_rfq_user_info](#private-get_block_rfq_user_info)
- [/private/get_block_rfqs](#private-get_block_rfqs)
- [/private/trade_block_rfq](#private-trade_block_rfq)

## /public/get_block_rfq_trades

Retrieves public information about block RFQ trades.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "public/get_block_rfq_trades",
  "params": {
    "currency": "BTC"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": [
    {
      "trade_id": "BTR-12345",
      "instrument_name": "BTC-PERPETUAL",
      "price": 50000,
      "amount": 10,
      "direction": "buy",
      "timestamp": 1634206091071
    }
  ]
}
```

## /private/add_block_rfq_quote

Adds a quote to an existing block RFQ.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "private/add_block_rfq_quote",
  "params": {
    "rfq_id": "RFQ-12345",
    "instrument_name": "BTC-PERPETUAL",
    "amount": 10,
    "price": 50000,
    "direction": "buy"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| rfq_id | string | The ID of the RFQ |
| instrument_name | string | The name of the instrument |
| amount | number | The amount to quote |
| price | number | The price to quote |
| direction | string | The direction of the quote, "buy" or "sell" |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "quote_id": "BRFQQ-12345"
  }
}
```

## /private/cancel_all_block_rfq_quotes

Cancels all block RFQ quotes for the current user.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "private/cancel_all_block_rfq_quotes"
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "canceled": 5
  }
}
```

## /private/cancel_block_rfq

Cancels a block RFQ.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "private/cancel_block_rfq",
  "params": {
    "rfq_id": "RFQ-12345"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| rfq_id | string | The ID of the RFQ to cancel |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {
    "success": true
  }
}
```

## /private/cancel_block_rfq_quote

Cancels a specific block RFQ quote.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "private/cancel_block_rfq_quote",
  "params": {
    "quote_id": "BRFQQ-12345"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| quote_id | string | The ID of the quote to cancel |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": {
    "success": true
  }
}
```

## /private/create_block_rfq

Creates a new block RFQ.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "private/create_block_rfq",
  "params": {
    "currency": "BTC",
    "instruments": [
      {
        "name": "BTC-PERPETUAL",
        "direction": "buy",
        "amount": 10
      }
    ],
    "target_makers": [1234, 5678]
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| instruments | array | List of instruments for the RFQ |
| instruments[].name | string | The name of the instrument |
| instruments[].direction | string | The direction, "buy" or "sell" |
| instruments[].amount | number | The amount requested |
| target_makers | array | Optional list of user IDs to target with the RFQ |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "result": {
    "rfq_id": "RFQ-12345"
  }
}
```

## /private/edit_block_rfq_quote

Edits an existing block RFQ quote.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "private/edit_block_rfq_quote",
  "params": {
    "quote_id": "BRFQQ-12345",
    "price": 51000
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| quote_id | string | The ID of the quote to edit |
| price | number | The new price for the quote |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "result": {
    "success": true
  }
}
```

## /private/get_block_rfq_makers

Retrieves a list of makers available for block RFQs.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "method": "private/get_block_rfq_makers",
  "params": {
    "currency": "BTC"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "result": [
    {
      "user_id": 1234,
      "name": "Market Maker 1"
    },
    {
      "user_id": 5678,
      "name": "Market Maker 2"
    }
  ]
}
```

## /private/get_block_rfq_quotes

Retrieves quotes for a specific block RFQ.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "method": "private/get_block_rfq_quotes",
  "params": {
    "rfq_id": "RFQ-12345"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| rfq_id | string | The ID of the RFQ |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "result": [
    {
      "quote_id": "BRFQQ-12345",
      "maker_id": 1234,
      "instrument_name": "BTC-PERPETUAL",
      "amount": 10,
      "price": 50000,
      "direction": "buy",
      "timestamp": 1634206091071,
      "status": "active"
    }
  ]
}
```

## /private/get_block_rfq_user_info

Retrieves information about the current user's block RFQ settings.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 10,
  "method": "private/get_block_rfq_user_info"
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 10,
  "result": {
    "is_maker": true,
    "can_create_rfqs": true,
    "blocked_makers": [9012],
    "maker_instruments": ["BTC-PERPETUAL", "ETH-PERPETUAL"]
  }
}
```

## /private/get_block_rfqs

Retrieves block RFQs for the current user.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 11,
  "method": "private/get_block_rfqs",
  "params": {
    "currency": "BTC",
    "status": "active"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| status | string | Optional filter by status: "active", "expired", "canceled", "traded" |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 11,
  "result": [
    {
      "rfq_id": "RFQ-12345",
      "creator_id": 1234,
      "currency": "BTC",
      "instruments": [
        {
          "name": "BTC-PERPETUAL",
          "direction": "buy",
          "amount": 10
        }
      ],
      "status": "active",
      "created_timestamp": 1634206091071,
      "expires_timestamp": 1634209691071
    }
  ]
}
```

## /private/trade_block_rfq

Executes a trade based on a block RFQ quote.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 12,
  "method": "private/trade_block_rfq",
  "params": {
    "quote_id": "BRFQQ-12345"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| quote_id | string | The ID of the quote to trade |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 12,
  "result": {
    "trade_id": "BTR-12345"
  }
}
```

For detailed information on each of these methods, including request parameters and response formats, please refer to the comprehensive DeribitAPI.md document.