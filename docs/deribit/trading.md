# Trading

This section describes the trading endpoints of the Deribit API.

## Methods

- [/private/buy](#private-buy)
- [/private/sell](#private-sell)
- [/private/edit](#private-edit)
- [/private/edit_by_label](#private-edit_by_label)
- [/private/cancel](#private-cancel)
- [/private/cancel_all](#private-cancel_all)
- [/private/cancel_all_by_currency](#private-cancel_all_by_currency)
- [/private/cancel_all_by_currency_pair](#private-cancel_all_by_currency_pair)
- [/private/cancel_all_by_instrument](#private-cancel_all_by_instrument)
- [/private/cancel_all_by_kind_or_type](#private-cancel_all_by_kind_or_type)
- [/private/cancel_by_label](#private-cancel_by_label)
- [/private/cancel_quotes](#private-cancel_quotes)
- [/private/close_position](#private-close_position)
- [/private/get_margins](#private-get_margins)
- [/private/get_mmp_config](#private-get_mmp_config)
- [/private/get_mmp_status](#private-get_mmp_status)
- [/private/get_open_orders](#private-get_open_orders)
- [/private/get_open_orders_by_currency](#private-get_open_orders_by_currency)
- [/private/get_open_orders_by_instrument](#private-get_open_orders_by_instrument)
- [/private/get_open_orders_by_label](#private-get_open_orders_by_label)
- [/private/get_order_history_by_currency](#private-get_order_history_by_currency)
- [/private/get_order_history_by_instrument](#private-get_order_history_by_instrument)
- [/private/get_order_margin_by_ids](#private-get_order_margin_by_ids)
- [/private/get_order_state](#private-get_order_state)
- [/private/get_order_state_by_label](#private-get_order_state_by_label)
- [/private/get_trigger_order_history](#private-get_trigger_order_history)
- [/private/get_user_trades_by_currency](#private-get_user_trades_by_currency)
- [/private/get_user_trades_by_currency_and_time](#private-get_user_trades_by_currency_and_time)
- [/private/get_user_trades_by_instrument](#private-get_user_trades_by_instrument)
- [/private/get_user_trades_by_instrument_and_time](#private-get_user_trades_by_instrument_and_time)
- [/private/get_user_trades_by_order](#private-get_user_trades_by_order)
- [/private/mass_quote](#private-mass_quote)
- [/private/move_positions](#private-move_positions)
- [/private/reset_mmp](#private-reset_mmp)
- [/private/send_rfq](#private-send_rfq)
- [/private/set_mmp_config](#private-set_mmp_config)
- [/private/get_settlement_history_by_instrument](#private-get_settlement_history_by_instrument)
- [/private/get_settlement_history_by_currency](#private-get_settlement_history_by_currency)

## /private/buy

Places a buy order for an instrument.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 5275,
  "method": "private/buy",
  "params": {
    "instrument_name": "BTC-PERPETUAL",
    "amount": 100,
    "type": "limit",
    "price": 9000,
    "time_in_force": "good_til_cancelled"
  }
}
```

### Parameters

| Name             | Type      | Description                                                                         |
|------------------|-----------|-------------------------------------------------------------------------------------|
| instrument_name  | string    | Instrument name                                                                     |
| amount           | number    | It represents either quantity or contract amount, depending on instrument settings. |
| price            | number    | The order price in base currency.                                                   |
| type             | string    | "limit" or "market", default: "limit"                                               |
| time_in_force    | string    | "good_til_cancelled", "fill_or_kill", "immediate_or_cancel"                         |
| max_show         | number    | Maximum amount to be shown to other traders, 0 for invisible order.                 |
| post_only        | boolean   | If true, the order is considered post-only.                                         |
| reduce_only      | boolean   | If true, the order is considered reduce-only.                                       |
| label            | string    | User defined label for the order (maximum 32 characters).                           |
| price_index      | string    | The index price.                                                                    |
| trigger          | string    | Trigger type. Supported values: "index_price", "mark_price", "last_price".          |
| trigger_price    | number    | Trigger price, required for trigger orders.                                         |

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 5275,
  "result": {
    "trades": [],
    "order": {
      "web": false,
      "time_in_force": "good_til_cancelled",
      "replaced": false,
      "reduce_only": false,
      "profit_loss": 0,
      "price": 9000,
      "post_only": false,
      "order_type": "limit",
      "order_state": "open",
      "order_id": "ETH-349253",
      "max_show": 100,
      "last_update_timestamp": 1550657341322,
      "label": "market0000234",
      "is_liquidation": false,
      "instrument_name": "BTC-PERPETUAL",
      "filled_amount": 0,
      "direction": "buy",
      "creation_timestamp": 1550657341322,
      "commission": 0,
      "average_price": 0,
      "api": true,
      "amount": 100
    }
  }
}
```

## /private/sell

Places a sell order for an instrument.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 5275,
  "method": "private/sell",
  "params": {
    "instrument_name": "BTC-PERPETUAL",
    "amount": 100,
    "type": "limit",
    "price": 11000,
    "time_in_force": "good_til_cancelled"
  }
}
```

### Response

> Example response:

Similar to /private/buy response.

## /private/cancel

Cancels an order, specified by order id.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 230,
  "method": "private/cancel",
  "params": {
    "order_id": "ETH-349253"
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 230,
  "result": {
    "web": false,
    "time_in_force": "good_til_cancelled",
    "replaced": false,
    "reduce_only": false,
    "profit_loss": 0,
    "price": 9000,
    "post_only": false,
    "order_type": "limit",
    "order_state": "cancelled",
    "order_id": "ETH-349253",
    "max_show": 100,
    "last_update_timestamp": 1550657341322,
    "label": "market0000234",
    "is_liquidation": false,
    "instrument_name": "BTC-PERPETUAL",
    "filled_amount": 0,
    "direction": "buy",
    "creation_timestamp": 1550657341322,
    "commission": 0,
    "average_price": 0,
    "api": true,
    "amount": 100
  }
}
```

<!-- Continue with other trading methods as necessary -->

For detailed information on each of these methods, including request parameters and response formats, please refer to the comprehensive DeribitAPI.md document.