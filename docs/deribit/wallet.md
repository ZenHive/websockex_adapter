# Wallet

This section describes the wallet-related endpoints of the Deribit API.

## Methods

- [/private/add_to_address_book](#private-add_to_address_book)
- [/private/cancel_transfer_by_id](#private-cancel_transfer_by_id)
- [/private/cancel_withdrawal](#private-cancel_withdrawal)
- [/private/create_deposit_address](#private-create_deposit_address)
- [/private/get_address_book](#private-get_address_book)
- [/private/get_current_deposit_address](#private-get_current_deposit_address)
- [/private/get_deposits](#private-get_deposits)
- [/private/get_transfers](#private-get_transfers)
- [/private/get_withdrawals](#private-get_withdrawals)
- [/private/remove_from_address_book](#private-remove_from_address_book)
- [/private/set_clearance_originator](#private-set_clearance_originator)
- [/private/submit_transfer_between_subaccounts](#private-submit_transfer_between_subaccounts)
- [/private/submit_transfer_to_subaccount](#private-submit_transfer_to_subaccount)
- [/private/submit_transfer_to_user](#private-submit_transfer_to_user)
- [/private/update_in_address_book](#private-update_in_address_book)
- [/private/withdraw](#private-withdraw)

## /private/add_to_address_book

Adds a new entry to the address book.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "private/add_to_address_book",
  "params": {
    "currency": "BTC",
    "type": "crypto",
    "address": "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
    "name": "Satoshi Donation Address"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| type | string | Type of the address, "crypto" |
| address | string | The address to add |
| name | string | Name for the address |
| tfa | string | Optional TFA code, required when TFA is enabled for the account |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": 1234
}
```

## /private/cancel_transfer_by_id

Cancels a transfer that has not been processed yet.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "private/cancel_transfer_by_id",
  "params": {
    "currency": "BTC",
    "id": 5
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| id | integer | The transfer ID |
| tfa | string | Optional TFA code, required when TFA is enabled for the account |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": true
}
```

## /private/cancel_withdrawal

Cancels a withdrawal that has not been processed yet.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "private/cancel_withdrawal",
  "params": {
    "currency": "BTC",
    "id": 6
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| id | integer | The withdrawal ID |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": true
}
```

## /private/create_deposit_address

Creates a new deposit address for the currency.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "private/create_deposit_address",
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
  "id": 6,
  "result": {
    "address": "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
    "creation_timestamp": 1550657341322,
    "currency": "BTC",
    "type": "bitcoin"
  }
}
```

## /private/get_address_book

Retrieves the address book entries.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "private/get_address_book",
  "params": {
    "currency": "BTC",
    "type": "crypto"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| type | string | Type of the address, "crypto" |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "result": [
    {
      "id": 1234,
      "currency": "BTC",
      "address": "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
      "name": "Satoshi Donation Address",
      "type": "crypto",
      "created_timestamp": 1550657341322
    }
  ]
}
```

## /private/get_current_deposit_address

Retrieves the current deposit address for a currency.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "method": "private/get_current_deposit_address",
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
  "result": {
    "address": "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
    "creation_timestamp": 1550657341322,
    "currency": "BTC",
    "type": "bitcoin"
  }
}
```

## /private/get_deposits

Retrieves the deposit history.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "method": "private/get_deposits",
  "params": {
    "currency": "BTC",
    "count": 10
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| count | integer | Number of requested items, default: 10 |
| offset | integer | The offset for pagination, default: 0 |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "result": [
    {
      "address": "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
      "amount": 0.1,
      "currency": "BTC",
      "received_timestamp": 1550657341322,
      "state": "completed",
      "transaction_id": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      "updated_timestamp": 1550657341322
    }
  ]
}
```

## /private/get_transfers

Retrieves transfer history.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 10,
  "method": "private/get_transfers",
  "params": {
    "currency": "BTC",
    "count": 10
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| count | integer | Number of requested items, default: 10 |
| offset | integer | The offset for pagination, default: 0 |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 10,
  "result": [
    {
      "amount": 0.1,
      "created_timestamp": 1550657341322,
      "currency": "BTC",
      "direction": "payment",
      "id": 1234,
      "other_side": "example@example.com",
      "state": "completed",
      "type": "user",
      "updated_timestamp": 1550657341322
    }
  ]
}
```

## /private/get_withdrawals

Retrieves withdrawal history.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 11,
  "method": "private/get_withdrawals",
  "params": {
    "currency": "BTC",
    "count": 10
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| count | integer | Number of requested items, default: 10 |
| offset | integer | The offset for pagination, default: 0 |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 11,
  "result": [
    {
      "address": "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
      "amount": 0.1,
      "confirmed_timestamp": 1550657341322,
      "created_timestamp": 1550657341322,
      "currency": "BTC",
      "fee": 0.0001,
      "id": 1234,
      "priority": 0.15,
      "state": "completed",
      "transaction_id": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
      "updated_timestamp": 1550657341322
    }
  ]
}
```

## /private/withdraw

Creates a withdrawal request.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 12,
  "method": "private/withdraw",
  "params": {
    "currency": "BTC",
    "address": "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
    "amount": 0.1,
    "priority": "0.15"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| address | string | The destination address |
| amount | number | The amount to withdraw |
| priority | string | The priority of the withdrawal, determines the fee |
| tfa | string | Optional TFA code, required when TFA is enabled for the account |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 12,
  "result": {
    "address": "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa",
    "amount": 0.1,
    "confirmed_timestamp": null,
    "created_timestamp": 1550657341322,
    "currency": "BTC",
    "fee": 0.0001,
    "id": 1234,
    "priority": 0.15,
    "state": "unconfirmed",
    "transaction_id": null,
    "updated_timestamp": 1550657341322
  }
}
```

For detailed information on each of these methods, including additional request parameters and response formats, please refer to the comprehensive DeribitAPI.md document.