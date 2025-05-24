# Subscription Management

## /public/subscribe

Subscribe to one or more public channels. Only available via WebSocket.

### Parameters

| Name     | Type  | Description           |
| -------- | ----- | --------------------- |
| channels | array | List of channel names |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 3600,
  "method": "public/subscribe",
  "params": {
    "channels": ["deribit_price_index.btc_usd"]
  }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 3600,
  "result": [
    {
      "channel": "deribit_price_index.btc_usd",
      "data": {
        /* channel-specific data */
      }
    }
  ]
}
```

### Response Fields

| Name    | Type    | Description                         |
| ------- | ------- | ----------------------------------- |
| id      | integer | The id that was sent in the request |
| jsonrpc | string  | The JSON-RPC version (2.0)          |
| result  | array   | List of subscription confirmations  |

---

## /public/unsubscribe

Unsubscribe from one or more public channels. Only available via WebSocket.

### Parameters

| Name     | Type  | Description           |
| -------- | ----- | --------------------- |
| channels | array | List of channel names |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 3601,
  "method": "public/unsubscribe",
  "params": {
    "channels": ["deribit_price_index.btc_usd"]
  }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 3601,
  "result": [
    {
      "channel": "deribit_price_index.btc_usd",
      "unsubscribed": true
    }
  ]
}
```

### Response Fields

| Name    | Type    | Description                          |
| ------- | ------- | ------------------------------------ |
| id      | integer | The id that was sent in the request  |
| jsonrpc | string  | The JSON-RPC version (2.0)           |
| result  | array   | List of unsubscription confirmations |

---

## /public/unsubscribe_all

Unsubscribe from all public channels. Only available via WebSocket.

### Parameters

_This method takes no parameters_

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 3602,
  "method": "public/unsubscribe_all",
  "params": {}
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 3602,
  "result": "ok"
}
```

### Response Fields

| Name    | Type    | Description                         |
| ------- | ------- | ----------------------------------- |
| id      | integer | The id that was sent in the request |
| jsonrpc | string  | The JSON-RPC version (2.0)          |
| result  | string  | Result of method execution          |

---

## /private/subscribe

Subscribe to one or more private channels. Only available via WebSocket and requires authentication.

### Parameters

| Name     | Type   | Description             |
| -------- | ------ | ----------------------- |
| channels | array  | List of channel names   |
| label    | string | (Optional) Custom label |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 3603,
  "method": "private/subscribe",
  "params": {
    "channels": ["user.orders.BTC-PERPETUAL.raw"]
  }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 3603,
  "result": [
    {
      "channel": "user.orders.BTC-PERPETUAL.raw",
      "data": {
        /* channel-specific data */
      }
    }
  ]
}
```

### Response Fields

| Name    | Type    | Description                         |
| ------- | ------- | ----------------------------------- |
| id      | integer | The id that was sent in the request |
| jsonrpc | string  | The JSON-RPC version (2.0)          |
| result  | array   | List of subscription confirmations  |

---

## /private/unsubscribe

Unsubscribe from one or more private channels. Only available via WebSocket and requires authentication.

### Parameters

| Name     | Type  | Description           |
| -------- | ----- | --------------------- |
| channels | array | List of channel names |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 3604,
  "method": "private/unsubscribe",
  "params": {
    "channels": ["user.orders.BTC-PERPETUAL.raw"]
  }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 3604,
  "result": [
    {
      "channel": "user.orders.BTC-PERPETUAL.raw",
      "unsubscribed": true
    }
  ]
}
```

### Response Fields

| Name    | Type    | Description                          |
| ------- | ------- | ------------------------------------ |
| id      | integer | The id that was sent in the request  |
| jsonrpc | string  | The JSON-RPC version (2.0)           |
| result  | array   | List of unsubscription confirmations |

---

## /private/unsubscribe_all

Unsubscribe from all private channels. Only available via WebSocket and requires authentication.

### Parameters

_This method takes no parameters_

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 3605,
  "method": "private/unsubscribe_all",
  "params": {}
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 3605,
  "result": "ok"
}
```

### Response Fields

| Name    | Type    | Description                         |
| ------- | ------- | ----------------------------------- |
| id      | integer | The id that was sent in the request |
| jsonrpc | string  | The JSON-RPC version (2.0)          |
| result  | string  | Result of method execution          |

---

## Channel Subscription Patterns

Channels are named using patterns such as:

- `book.{instrument_name}.{group}.{depth}.{interval}`
- `user.orders.{instrument_name}.{interval}`
- `user.trades.{kind}.{currency}.{interval}`

Refer to the API documentation for channel-specific parameters and response fields.
