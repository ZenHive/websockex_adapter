# JSON-RPC

JSON-RPC is a light-weight remote procedure call (RPC) protocol. The
[JSON-RPC specification](https://www.jsonrpc.org/specification) defines the data
structures that are used for the messages that are exchanged between client
and server, as well as the rules around their processing. JSON-RPC uses
JSON (RFC 4627) as data format.

JSON-RPC is transport agnostic: it does not specify which transport
mechanism must be used. The Deribit API supports both Websocket (preferred)
and HTTP (with limitations: subscriptions are not supported over HTTP).

-- WARNING ---
The JSON-RPC specification describes two features that are currently not supported by the API:
- Specification of parameter values by position
- Batch requests

## Request messages

> An example of a request message:

```json
{
    "jsonrpc": "2.0",
    "id": 8066,
    "method": "public/ticker",
    "params": {
        "instrument": "BTC-24AUG18-6500-P"
    }
}
```

According to the JSON-RPC specification the requests must be JSON objects with the following fields.

| Name | Type | Description |
| --- | --- | --- |
| jsonrpc | string | The version of the JSON-RPC spec: "2.0" |
| id | integer or string | An identifier of the request. If it is included, then the response will contain the same identifier |
| method | string | The method to be invoked |
| params | object | The parameters values for the method. The field names must match with the expected parameter names. The parameters that are expected are described in the documentation for the methods, below. |

## Response messages

> An example of a response message:

```json
{
    "jsonrpc": "2.0",
    "id": 5239,
    "testnet": false,
    "result": [
        {
            "coin_type": "BITCOIN",
            "currency": "BTC",
            "currency_long": "Bitcoin",
            "fee_precision": 4,
            "min_confirmations": 1,
            "min_withdrawal_fee": 0.0001,
            "withdrawal_fee": 0.0001,
            "withdrawal_priorities": [
                {
                    "value": 0.15,
                    "name": "very_low"
                },
                {
                    "value": 1.5,
                    "name": "very_high"
                }
            ]
        }
    ],
    "usIn": 1535043730126248,
    "usOut": 1535043730126250,
    "usDiff": 2
}
```

The JSON-RPC API always responds with a JSON object with the following fields.

| Name | Type | Description |
| --- | --- | --- |
| id | integer | This is the same id that was sent in the request. |
| result | any | If successful, the result of the API call. The format for the result is described with each method. |
| error | error object | Only present if there was an error invoking the method. The error object is described below. |
| testnet | boolean | Indicates whether the API in use is actually the test API. `false` for production server, `true` for test server. |
| usIn | integer | The timestamp when the requests was received (microseconds since the Unix epoch) |
| usOut | integer | The timestamp when the response was sent (microseconds since the Unix epoch) |
| usDiff | integer | The number of microseconds that was spent handling the request |

> An example of a response with an error:

```json
{
    "jsonrpc": "2.0",
    "id": 8163,
    "error": {
        "code": 11050,
        "message": "bad_request"
    },
    "testnet": false,
    "usIn": 1535037392434763,
    "usOut": 1535037392448119,
    "usDiff": 13356
}
```

In case of an error the response message will contain the error field, with
as value an object with the following with the following fields:

| Name | Type | Description |
| --- | --- | --- |
| code | integer | A number that indicates the kind of error. |
| message | string | A short description that indicates the kind of error. |
| data | any | Additional data about the error. This field may be omitted. |

## Detailed response for `private/cancel_all*` and `private/cancel_by_label` methods

> An example of a positive execution of cancellation trigger orders in ETH-PERPETUAL when one order was cancelled:

```json
{
    "currency": "BTC",
    "type": "trigger",
    "instrument_name": "ETH-PERPETUAL",
    "result": [{
      "web": true,
      "triggered": false,
      "trigger_price": 1628.7,
      "trigger": "last_price",
      "time_in_force": "good_til_cancelled",
      "replaced": false,
      "reduce_only": false,
      "price": "market_price",
      "post_only": false,
      "order_type": "stop_market",
      "order_state": "untriggered",
      "order_id": "ETH-SLTS-250756",
      "max_show": 100,
      "last_update_timestamp": 1634206091071,
      "label": "",
      "is_rebalance": false,
      "is_liquidation": false,
      "instrument_name": "ETH-PERPETUAL",
      "direction": "sell",
      "creation_timestamp": 1634206000230,
      "api": false,
      "amount": 100
    }]
}
```

When boolean parameter `detailed` with value `true` is added to `cancel_all*` or `cancel_by_label` methods response format
is changed. Instead of the number of cancelled orders there is a returned list of execution reports objects for every requested instrument, order type and currency:
results of positive or erroneous execution. It is done this way because internally during processing
cancel_all request there are done separate requests for every currency, order type and book.

### Positive execution report

Positive execution report is object with fields:

- `currency`
- `type` - `trigger` or `limit`
- `instrument_name`
- `result` - array of orders formatted like in `private/cancel` response

### Erroneous execution report

Erroneous execution report is object with fields:

- `currency`
- `type` - `trigger` or `limit`
- `instrument_name` - it is attached only if the error is related to specific instrument
- `error` - error message formatted as usual

> An example of information that cancel of limit orders in ETH failed:

```json
{
  "currency": "ETH",
  "type": "limit",
  "error": {
    "message": "matching_engine_queue_full",
    "code": 10047
  }
}
```

## Security keys

> Request that may require security key authorization

## Notifications

## Authentication

## Access scope

## Creating/editing/removing API Keys

## JSON-RPC over websocket

## JSON-RPC over HTTP