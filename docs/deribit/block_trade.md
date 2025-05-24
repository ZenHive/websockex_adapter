# Block Trade

This section describes the block trade endpoints of the Deribit API. Block trades are privately negotiated trades that are executed outside of the public order book.

## Methods

- [/private/approve_block_trade](#private-approve_block_trade)
- [/private/execute_block_trade](#private-execute_block_trade)
- [/private/get_block_trade](#private-get_block_trade)
- [/private/get_block_trades](#private-get_block_trades)
- [/private/get_pending_block_trades](#private-get_pending_block_trades)
- [/private/invalidate_block_trade_signature](#private-invalidate_block_trade_signature)
- [/private/reject_block_trade](#private-reject_block_trade)
- [/private/simulate_block_trade](#private-simulate_block_trade)
- [/private/verify_block_trade](#private-verify_block_trade)

## /private/approve_block_trade

Approves a block trade that was created by an initiator.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "private/approve_block_trade",
  "params": {
    "trade_id": "BTC-100001"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| trade_id | string | The ID of the block trade to approve |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "trade_id": "BTC-100001"
  }
}
```

## /private/execute_block_trade

Creates a block trade. When this method is called by an initiator, a block trade request will be sent to the counterparty for approval.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "private/execute_block_trade",
  "params": {
    "trades": [
      {
        "instrument_name": "BTC-PERPETUAL",
        "amount": 10,
        "price": 9000,
        "direction": "buy",
        "label": "market0000234"
      }
    ],
    "counterparty_user_id": 1234
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| trades | array | List of trades |
| trades[].instrument_name | string | The name of the instrument |
| trades[].amount | number | The amount of contracts |
| trades[].price | number | The price of the contracts |
| trades[].direction | string | The direction of the trade, "buy" or "sell" |
| trades[].label | string | Optional label for the trade |
| counterparty_user_id | integer | The user ID of the counterparty |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "trade_id": "BTC-100001"
  }
}
```

## /private/get_block_trade

Retrieves a single block trade by its ID.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "private/get_block_trade",
  "params": {
    "trade_id": "BTC-100001"
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "trade_id": "BTC-100001",
    "initiator_user_id": 5678,
    "counterparty_user_id": 1234,
    "state": "approved",
    "created_timestamp": 1550657341322,
    "updated_timestamp": 1550657342100,
    "legs": [
      {
        "instrument_name": "BTC-PERPETUAL",
        "amount": 10,
        "price": 9000,
        "direction": "buy",
        "label": "market0000234"
      }
    ]
  }
}
```

## /private/get_block_trades

Retrieves a list of block trades for the current user.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "private/get_block_trades",
  "params": {
    "state": "approved"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| state | string | Optional. Filter by state: "pending", "approved", "rejected" |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": [
    {
      "trade_id": "BTC-100001",
      "initiator_user_id": 5678,
      "counterparty_user_id": 1234,
      "state": "approved",
      "created_timestamp": 1550657341322,
      "updated_timestamp": 1550657342100,
      "legs": [
        {
          "instrument_name": "BTC-PERPETUAL",
          "amount": 10,
          "price": 9000,
          "direction": "buy",
          "label": "market0000234"
        }
      ]
    }
  ]
}
```

## /private/get_pending_block_trades

Retrieves a list of pending block trades for the current user.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "private/get_pending_block_trades"
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": [
    {
      "trade_id": "BTC-100002",
      "initiator_user_id": 5678,
      "counterparty_user_id": 1234,
      "state": "pending",
      "created_timestamp": 1550657341322,
      "updated_timestamp": 1550657341322,
      "legs": [
        {
          "instrument_name": "BTC-PERPETUAL",
          "amount": 5,
          "price": 9100,
          "direction": "sell",
          "label": "market0000235"
        }
      ]
    }
  ]
}
```

## /private/invalidate_block_trade_signature

Invalidates the signature for a given block trade.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "private/invalidate_block_trade_signature",
  "params": {
    "trade_id": "BTC-100001",
    "signature_id": "sig123456"
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "result": {
    "success": true
  }
}
```

## /private/reject_block_trade

Rejects a block trade that was created by an initiator.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "private/reject_block_trade",
  "params": {
    "trade_id": "BTC-100002"
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "result": {
    "trade_id": "BTC-100002"
  }
}
```

## /private/simulate_block_trade

Simulates the execution of a block trade to check if it would be accepted.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "method": "private/simulate_block_trade",
  "params": {
    "trades": [
      {
        "instrument_name": "BTC-PERPETUAL",
        "amount": 10,
        "price": 9000,
        "direction": "buy",
        "label": "market0000234"
      }
    ],
    "counterparty_user_id": 1234
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "result": {
    "valid": true
  }
}
```

## /private/verify_block_trade

Verifies a block trade signature.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "method": "private/verify_block_trade",
  "params": {
    "trade_id": "BTC-100001",
    "signature": "0x...",
    "public_key": "0x..."
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "result": {
    "valid": true
  }
}
```

For detailed information on each of these methods, including request parameters and response formats, please refer to the comprehensive DeribitAPI.md document.