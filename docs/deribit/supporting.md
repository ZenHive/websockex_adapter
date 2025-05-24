# Supporting

## /public/get_time

Retrieves the current time (in milliseconds). Useful for checking clock skew between your software and Deribit's systems.

### Parameters

_This method takes no parameters_

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 7365,
  "method": "public/get_time",
  "params": {}
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 7365,
  "result": 1550147385946
}
```

### Response Fields

| Name    | Type    | Description                                  |
| ------- | ------- | -------------------------------------------- |
| id      | integer | The id that was sent in the request          |
| jsonrpc | string  | The JSON-RPC version (2.0)                   |
| result  | integer | Current timestamp (milliseconds since epoch) |

---

## /public/hello

Introduce the client software to Deribit over WebSocket. Deribit will also introduce itself in the response.

### Parameters

| Name           | Type   | Description             |
| -------------- | ------ | ----------------------- |
| client_name    | string | Client software name    |
| client_version | string | Client software version |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 2841,
  "method": "public/hello",
  "params": {
    "client_name": "My Trading Software",
    "client_version": "1.0.2"
  }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 2841,
  "result": {
    "version": "1.2.26"
  }
}
```

### Response Fields

| Name      | Type    | Description                         |
| --------- | ------- | ----------------------------------- |
| id        | integer | The id that was sent in the request |
| jsonrpc   | string  | The JSON-RPC version (2.0)          |
| result    | object  |                                     |
| › version | string  | The API version                     |

---

## /public/status

Get information about locked currencies on the platform.

### Parameters

_This method takes no parameters_

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 55,
  "method": "public/status",
  "params": {}
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 55,
  "result": {
    "locked_currencies": ["BTC", "ETH"],
    "locked": true
  }
}
```

### Response Fields

| Name             | Type    | Description                                                         |
| ---------------- | ------- | ------------------------------------------------------------------- |
| id               | integer | The id that was sent in the request                                 |
| jsonrpc          | string  | The JSON-RPC version (2.0)                                          |
| result           | object  |                                                                     |
| › locked         | string  | `true` if all currencies locked, `partial` if some, `false` if none |
| › locked_indices | array   | List of currency indices locked platform-wise                       |

---

## /public/test

Tests the connection to the API server and returns its version. Use to verify API reachability and version.

### Parameters

| Name            | Type   | Description                                      |
| --------------- | ------ | ------------------------------------------------ |
| expected_result | string | (Optional) If set to "exception", triggers error |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 8212,
  "method": "public/test",
  "params": {}
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 8212,
  "result": {
    "version": "1.2.26"
  }
}
```

### Response Fields

| Name      | Type    | Description                         |
| --------- | ------- | ----------------------------------- |
| id        | integer | The id that was sent in the request |
| jsonrpc   | string  | The JSON-RPC version (2.0)          |
| result    | object  |                                     |
| › version | string  | The API version                     |
