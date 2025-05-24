# Combo Books

This section describes the combo books endpoints of the Deribit API. Combo books allow trading combinations of instruments as a single order.

## Methods

- [/public/get_combo_details](#public-get_combo_details)
- [/public/get_combo_ids](#public-get_combo_ids)
- [/public/get_combos](#public-get_combos)
- [/private/create_combo](#private-create_combo)
- [/private/get_leg_prices](#private-get_leg_prices)

## /public/get_combo_details

Retrieves combo details for a given combo ID.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 42,
  "method": "public/get_combo_details",
  "params": {
    "combo_id": "BTC-13OCT23-30000-C+BTC-20OCT23-29000-C"
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 42,
  "result": {
    "creation_timestamp": 1634206091071,
    "instruments": [
      {
        "direction": "buy",
        "instrument_name": "BTC-13OCT23-30000-C",
        "ratio": 1
      },
      {
        "direction": "sell",
        "instrument_name": "BTC-20OCT23-29000-C",
        "ratio": 1
      }
    ],
    "is_default": false,
    "combo_name": "BTC-13OCT23-30000-C+BTC-20OCT23-29000-C",
    "combo_id": "BTC-13OCT23-30000-C+BTC-20OCT23-29000-C",
    "creator_user_id": 1234
  }
}
```

## /public/get_combo_ids

Retrieves a list of combo IDs for a given currency.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 43,
  "method": "public/get_combo_ids",
  "params": {
    "currency": "BTC"
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 43,
  "result": [
    "BTC-13OCT23-30000-C+BTC-20OCT23-29000-C",
    "BTC-13OCT23-28000-P+BTC-20OCT23-27000-P"
  ]
}
```

## /public/get_combos

Retrieves combos for a given currency.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 44,
  "method": "public/get_combos",
  "params": {
    "currency": "BTC"
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 44,
  "result": [
    {
      "creation_timestamp": 1634206091071,
      "instruments": [
        {
          "direction": "buy",
          "instrument_name": "BTC-13OCT23-30000-C",
          "ratio": 1
        },
        {
          "direction": "sell",
          "instrument_name": "BTC-20OCT23-29000-C",
          "ratio": 1
        }
      ],
      "is_default": false,
      "combo_name": "BTC-13OCT23-30000-C+BTC-20OCT23-29000-C",
      "combo_id": "BTC-13OCT23-30000-C+BTC-20OCT23-29000-C",
      "creator_user_id": 1234
    }
  ]
}
```

## /private/create_combo

Creates a combo for a given list of instruments.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 8106,
  "method": "private/create_combo",
  "params": {
    "instruments": [
      {
        "instrument_name": "BTC-13OCT23-30000-C",
        "direction": "buy",
        "ratio": 1
      },
      {
        "instrument_name": "BTC-20OCT23-29000-C",
        "direction": "sell",
        "ratio": 1
      }
    ]
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 8106,
  "result": {
    "combo_id": "BTC-13OCT23-30000-C+BTC-20OCT23-29000-C"
  }
}
```

## /private/get_leg_prices

Returns the prices for leg instruments in a combo.

### Request

> Example request:

```json
{
  "jsonrpc": "2.0",
  "id": 8107,
  "method": "private/get_leg_prices",
  "params": {
    "instruments": [
      {
        "instrument_name": "BTC-13OCT23-30000-C",
        "direction": "buy",
        "ratio": 1
      },
      {
        "instrument_name": "BTC-20OCT23-29000-C",
        "direction": "sell",
        "ratio": 1
      }
    ],
    "total_price": 0.05
  }
}
```

### Response

> Example response:

```json
{
  "jsonrpc": "2.0",
  "id": 8107,
  "result": [
    {
      "instrument_name": "BTC-13OCT23-30000-C",
      "price": 0.03
    },
    {
      "instrument_name": "BTC-20OCT23-29000-C",
      "price": 0.02
    }
  ]
}
```

For detailed information on each of these methods, including request parameters and response formats, please refer to the comprehensive DeribitAPI.md document.