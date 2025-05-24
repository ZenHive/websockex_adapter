# Authentication

## /public/auth

Retrieve an Oauth access token, to be used for authentication of 'private' requests.

### Parameters

| Name          | Type    | Description                                                                                                                                                                                                                                                                                                                |
| ------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| grant_type    | string  | Method of authentication                                                                                                                                                                                                                                                                                                   |
| client_id     | string  | Required for grant type `client_credentials` and `client_signature`                                                                                                                                                                                                                                                        |
| client_secret | string  | Required for grant type `client_credentials`                                                                                                                                                                                                                                                                               |
| refresh_token | string  | Required for grant type `refresh_token`                                                                                                                                                                                                                                                                                    |
| timestamp     | integer | Required for grant type `client_signature`, provides time when request has been generated (milliseconds since the UNIX epoch)                                                                                                                                                                                              |
| signature     | string  | Required for grant type `client_signature`; it's a cryptographic signature calculated over provided fields using user **secret key**. The signature should be calculated as an HMAC (Hash-based Message Authentication Code) with `SHA256` hash algorithm                                                                  |
| nonce         | string  | Optional for grant type `client_signature`; delivers user generated initialization vector for the server token                                                                                                                                                                                                             |
| data          | string  | Optional for grant type `client_signature`; contains any user specific value                                                                                                                                                                                                                                               |
| state         | string  | Will be passed back in the response                                                                                                                                                                                                                                                                                        |
| scope         | string  | Describes type of the access for assigned token, possible values: `connection`, `session:name`, `trade:[read, read_write, none]`, `wallet:[read, read_write, none]`, `account:[read, read_write, none]`, `expires:NUMBER`, `ip:ADDR`.<br> Details are elucidated in [Access scope](https://docs.deribit.com/#access-scope) |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 9929,
  "method": "public/auth",
  "params": {
    "grant_type": "client_credentials",
    "client_id": "fo7WAPRm4P",
    "client_secret": "W0H6FJW4IRPZ1MOQ8FP6KMC5RZDUUKXS"
  }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 9929,
  "result": {
    "access_token": "...",
    "expires_in": 31536000,
    "refresh_token": "...",
    "scope": "connection mainaccount",
    "enabled_features": [],
    "token_type": "bearer"
  }
}
```

### Response Fields

| Name                    | Type            | Description                                                 |
| ----------------------- | --------------- | ----------------------------------------------------------- |
| id                      | integer         | The id that was sent in the request                         |
| jsonrpc                 | string          | The JSON-RPC version (2.0)                                  |
| result                  | object          |                                                             |
| ›  access_token         | string          |                                                             |
| ›  enabled_features     | array of string | List of enabled advanced on-key features.                   |
| ›  expires_in           | integer         | Token lifetime in seconds                                   |
| ›  google_login         | boolean         | The access token was acquired by logging in through Google. |
| ›  mandatory_tfa_status | string          | 2FA is required for privileged methods                      |
| ›  refresh_token        | string          | Can be used to request a new token (with a new lifetime)    |
| ›  scope                | string          | Type of the access for assigned token                       |
| ›  sid                  | string          | Optional Session id                                         |
| ›  state                | string          | Copied from the input (if applicable)                       |
| ›  token_type           | string          | Authorization type, allowed value - `bearer`                |

---

## /public/exchange_token

Generates a token for a new subject id. This method can be used to switch between subaccounts.

### Parameters

| Name          | Type    | Description    |
| ------------- | ------- | -------------- |
| refresh_token | string  | Refresh token  |
| subject_id    | integer | New subject id |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 7619,
  "method": "public/exchange_token",
  "params": {
    "refresh_token": "...",
    "subject_id": 10
  }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 9929,
  "result": {
    "access_token": "...",
    "expires_in": 31536000,
    "refresh_token": "...",
    "scope": "session:named_session mainaccount",
    "token_type": "bearer"
  }
}
```

### Response Fields

| Name             | Type    | Description                                              |
| ---------------- | ------- | -------------------------------------------------------- |
| id               | integer | The id that was sent in the request                      |
| jsonrpc          | string  | The JSON-RPC version (2.0)                               |
| result           | object  |                                                          |
| ›  access_token  | string  |                                                          |
| ›  expires_in    | integer | Token lifetime in seconds                                |
| ›  refresh_token | string  | Can be used to request a new token (with a new lifetime) |
| ›  scope         | string  | Type of the access for assigned token                    |
| ›  sid           | string  | Optional Session id                                      |
| ›  token_type    | string  | Authorization type, allowed value - `bearer`             |

---

## /public/fork_token

Generates a token for a new named session. This method can be used only with session scoped tokens.

### Parameters

| Name          | Type   | Description      |
| ------------- | ------ | ---------------- |
| refresh_token | string | Refresh token    |
| session_name  | string | New session name |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "id": 7620,
  "method": "public/fork_token",
  "params": {
    "refresh_token": "...",
    "session_name": "forked_session_name"
  }
}
```

### JSON-RPC Response

```json
{
  "jsonrpc": "2.0",
  "id": 9929,
  "result": {
    "access_token": "...",
    "expires_in": 31536000,
    "refresh_token": "...",
    "scope": "session:named_session mainaccount",
    "token_type": "bearer"
  }
}
```

### Response Fields

| Name             | Type    | Description                                              |
| ---------------- | ------- | -------------------------------------------------------- |
| id               | integer | The id that was sent in the request                      |
| jsonrpc          | string  | The JSON-RPC version (2.0)                               |
| result           | object  |                                                          |
| ›  access_token  | string  |                                                          |
| ›  expires_in    | integer | Token lifetime in seconds                                |
| ›  refresh_token | string  | Can be used to request a new token (with a new lifetime) |
| ›  scope         | string  | Type of the access for assigned token                    |
| ›  sid           | string  | Optional Session id                                      |
| ›  token_type    | string  | Authorization type, allowed value - `bearer`             |

---

## /private/logout

_This method is only available via websockets._

Gracefully close websocket connection, when COD (Cancel On Disconnect) is enabled orders are not cancelled

### Parameters

| Name             | Type    | Description                                                                               |
| ---------------- | ------- | ----------------------------------------------------------------------------------------- |
| invalidate_token | boolean | If value is `true` all tokens created in current session are invalidated, default: `true` |

### JSON-RPC Request

```json
{
  "jsonrpc": "2.0",
  "method": "private/logout",
  "id": 42,
  "params": {
    "access_token": "...",
    "invalidate_token": true
  }
}
```

### Response

_This method has no response body_
