# Session Management

## /public/set_heartbeat

Signals the WebSocket connection to send and request heartbeats. Heartbeats can be used to detect stale connections.

### Parameters

| Name     | Type   | Description                                 |
| -------- | ------ | ------------------------------------------- |
| interval | number | The heartbeat interval in seconds (min: 10) |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 9098,
  "method": "public/set_heartbeat",
  "params": { "interval": 30 }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 9098,
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

## /public/disable_heartbeat

Stop sending heartbeat messages.

### Parameters

_This method takes no parameters_

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 3562,
  "method": "public/disable_heartbeat",
  "params": {}
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 3562,
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

## /private/enable_cancel_on_disconnect

Enable Cancel On Disconnect for the connection. All orders created by the connection will be removed when the connection is closed.

### Parameters

| Name  | Type   | Description                                                                            |
| ----- | ------ | -------------------------------------------------------------------------------------- |
| scope | string | Specifies if Cancel On Disconnect applies to the current connection or the account.    |
|       |        | Enum: `connection`, `account` (default: `connection`). `connection` is WebSocket only. |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 7859,
  "method": "private/enable_cancel_on_disconnect",
  "params": { "scope": "account" }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 7859,
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

## /private/disable_cancel_on_disconnect

Disable Cancel On Disconnect for the connection.

### Parameters

| Name  | Type   | Description                                                                            |
| ----- | ------ | -------------------------------------------------------------------------------------- |
| scope | string | Specifies if Cancel On Disconnect applies to the current connection or the account.    |
|       |        | Enum: `connection`, `account` (default: `connection`). `connection` is WebSocket only. |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 1569,
  "method": "private/disable_cancel_on_disconnect",
  "params": { "scope": "account" }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 1569,
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

## /private/get_cancel_on_disconnect

Read current Cancel On Disconnect configuration for the account.

### Parameters

| Name  | Type   | Description                                                                            |
| ----- | ------ | -------------------------------------------------------------------------------------- |
| scope | string | Specifies if Cancel On Disconnect applies to the current connection or the account.    |
|       |        | Enum: `connection`, `account` (default: `connection`). `connection` is WebSocket only. |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 220,
  "method": "private/get_cancel_on_disconnect",
  "params": { "scope": "account" }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 220,
  "result": {
    "scope": "account",
    "enabled": false
  }
}
```

### Response Fields

| Name      | Type    | Description                                                        |
| --------- | ------- | ------------------------------------------------------------------ |
| id        | integer | The id that was sent in the request                                |
| jsonrpc   | string  | The JSON-RPC version (2.0)                                         |
| result    | object  |                                                                    |
| › scope   | string  | Informs if Cancel on Disconnect was checked for connection/account |
| › enabled | boolean | Current configuration status                                       |
