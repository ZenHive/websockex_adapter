# Account Management

This section describes the account management endpoints of the Deribit API.

## Methods

- [/public/get_announcements](#public-get_announcements)
- [/public/get_portfolio_margins](#public-get_portfolio_margins)
- [/private/change_api_key_name](#private-change_api_key_name)
- [/private/change_margin_model](#private-change_margin_model)
- [/private/change_scope_in_api_key](#private-change_scope_in_api_key)
- [/private/change_subaccount_name](#private-change_subaccount_name)
- [/private/create_api_key](#private-create_api_key)
- [/private/create_subaccount](#private-create_subaccount)
- [/private/disable_api_key](#private-disable_api_key)
- [/private/edit_api_key](#private-edit_api_key)
- [/private/enable_affiliate_program](#private-enable_affiliate_program)
- [/private/enable_api_key](#private-enable_api_key)
- [/private/get_access_log](#private-get_access_log)
- [/private/get_account_summaries](#private-get_account_summaries)
- [/private/get_account_summary](#private-get_account_summary)
- [/private/get_affiliate_program_info](#private-get_affiliate_program_info)
- [/private/get_email_language](#private-get_email_language)
- [/private/get_new_announcements](#private-get_new_announcements)
- [/private/get_portfolio_margins](#private-get_portfolio_margins)
- [/private/get_position](#private-get_position)
- [/private/get_positions](#private-get_positions)
- [/private/get_subaccounts](#private-get_subaccounts)
- [/private/get_subaccounts_details](#private-get_subaccounts_details)
- [/private/get_transaction_log](#private-get_transaction_log)
- [/private/get_user_locks](#private-get_user_locks)
- [/private/list_api_keys](#private-list_api_keys)
- [/private/list_custody_accounts](#private-list_custody_accounts)
- [/private/pme/simulate](#private-pme-simulate)
- [/private/remove_api_key](#private-remove_api_key)
- [/private/remove_subaccount](#private-remove_subaccount)
- [/private/reset_api_key](#private-reset_api_key)
- [/private/set_announcement_as_read](#private-set_announcement_as_read)
- [/private/set_disabled_trading_products](#private-set_disabled_trading_products)
- [/private/set_email_for_subaccount](#private-set_email_for_subaccount)
- [/private/set_email_language](#private-set_email_language)
- [/private/set_self_trading_config](#private-set_self_trading_config)
- [/private/simulate_portfolio](#private-simulate_portfolio)
- [/private/toggle_notifications_from_subaccount](#private-toggle_notifications_from_subaccount)
- [/private/toggle_subaccount_login](#private-toggle_subaccount_login)

## /public/get_announcements

Retrieves announcements from the past 30 days.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "public/get_announcements"
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": [
    {
      "title": "Deribit Futures and Options Trading Schedule",
      "publication_timestamp": 1550657341322,
      "body": "The following contract specifications...",
      "id": 1234
    }
  ]
}
```

## /private/get_account_summary

Retrieves user account summary.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "private/get_account_summary",
  "params": {
    "currency": "BTC",
    "extended": true
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| extended | boolean | Include additional fields |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "available_funds": 1.1,
    "available_withdrawal_funds": 1.0,
    "balance": 1.1,
    "currency": "BTC",
    "delta_total": 0,
    "equity": 1.1,
    "initial_margin": 0,
    "maintenance_margin": 0,
    "margin_balance": 1.1,
    "options_delta": 0,
    "options_gamma": 0,
    "options_pl": 0,
    "options_theta": 0,
    "options_value": 0,
    "options_vega": 0,
    "portfolio_margining_enabled": false,
    "session_funding": 0,
    "session_rpl": 0,
    "session_upl": 0,
    "session_upl_options": 0,
    "system_maintenance_margin": 0,
    "total_pl": 0,
    "username": "user123"
  }
}
```

## /private/get_positions

Retrieves user positions.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "private/get_positions",
  "params": {
    "currency": "BTC",
    "kind": "future"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| currency | string | The currency symbol |
| kind | string | Instrument kind, "future" or "option" |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": [
    {
      "average_price": 9000,
      "delta": 0.1,
      "direction": "buy",
      "estimated_liquidation_price": 0,
      "floating_profit_loss": 0,
      "index_price": 9050,
      "initial_margin": 0.01,
      "instrument_name": "BTC-PERPETUAL",
      "kind": "future",
      "maintenance_margin": 0.005,
      "mark_price": 9050,
      "open_orders_margin": 0,
      "realized_profit_loss": 0,
      "settlement_price": 9050,
      "size": 0.1,
      "size_currency": 900,
      "total_profit_loss": 0
    }
  ]
}
```

## /private/get_position

Retrieves user position for a specific instrument.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "private/get_position",
  "params": {
    "instrument_name": "BTC-PERPETUAL"
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| instrument_name | string | The instrument name |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {
    "average_price": 9000,
    "delta": 0.1,
    "direction": "buy",
    "estimated_liquidation_price": 0,
    "floating_profit_loss": 0,
    "index_price": 9050,
    "initial_margin": 0.01,
    "instrument_name": "BTC-PERPETUAL",
    "kind": "future",
    "maintenance_margin": 0.005,
    "mark_price": 9050,
    "open_orders_margin": 0,
    "realized_profit_loss": 0,
    "settlement_price": 9050,
    "size": 0.1,
    "size_currency": 900,
    "total_profit_loss": 0
  }
}
```

## /private/create_api_key

Creates a new API key for the user.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "private/create_api_key",
  "params": {
    "name": "My Trading Bot",
    "scope": "trade",
    "account_id": null
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| name | string | Key name |
| scope | string | Key permission scope ("read", "trade", "withdrawal") |
| account_id | integer | Account ID, leave null for current account |
| tfa | string | Optional TFA code, required when TFA is enabled for the account |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "result": {
    "id": "ABCDEFGH",
    "key": "abcdefgh-1234-5678-9abc-defghijklmno",
    "account_id": 1234,
    "scope": "trade",
    "name": "My Trading Bot",
    "secret": "ABCD1234ABCD1234ABCD1234ABCD1234",
    "created_at": 1550657341322,
    "active": true
  }
}
```

## /private/list_api_keys

Lists all API keys for the user.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "private/list_api_keys"
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 6,
  "result": [
    {
      "id": "ABCDEFGH",
      "key": "abcdefgh-1234-5678-9abc-defghijklmno",
      "account_id": 1234,
      "scope": "trade",
      "name": "My Trading Bot",
      "created_at": 1550657341322,
      "active": true
    }
  ]
}
```

## /private/get_transaction_log

Retrieves transaction log for the account.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "private/get_transaction_log",
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
| start_timestamp | integer | Start timestamp |
| end_timestamp | integer | End timestamp |
| count | integer | Number of entries to return, default: 10 |
| offset | integer | Pagination offset, default: 0 |
| types | array | Transaction types to include |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "result": {
    "count": 1,
    "logs": [
      {
        "amount": 0.1,
        "asset": "BTC",
        "commission": 0,
        "date": 1550657341322,
        "fee": 0,
        "description": "Deposit",
        "id": 1234,
        "type": "deposit"
      }
    ]
  }
}
```

## /private/get_subaccounts

Retrieves user subaccounts.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "method": "private/get_subaccounts",
  "params": {
    "with_portfolio": true
  }
}
```

### Parameters

| Name | Type | Description |
| --- | --- | --- |
| with_portfolio | boolean | Include portfolio info |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "result": [
    {
      "account_id": 5678,
      "can_login": true,
      "is_active": true,
      "username": "subaccount1",
      "email": null,
      "email_verified": false,
      "portfolio": [
        {
          "available_funds": 1.0,
          "available_withdrawal_funds": 1.0,
          "balance": 1.0,
          "currency": "BTC",
          "equity": 1.0,
          "initial_margin": 0,
          "maintenance_margin": 0,
          "margin_balance": 1.0
        }
      ]
    }
  ]
}
```

## /private/create_subaccount

Creates a new subaccount.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "method": "private/create_subaccount"
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 9,
  "result": {
    "account_id": 5678,
    "can_login": false,
    "is_active": true,
    "username": "subaccount2",
    "email": null,
    "email_verified": false
  }
}
```

For detailed information on each of these methods, including request parameters and response formats, please refer to the comprehensive DeribitAPI.md document.