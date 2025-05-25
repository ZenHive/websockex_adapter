defmodule WebsockexAdapter.Examples.DeribitRpc do
  @moduledoc """
  Shared Deribit JSON-RPC method definitions and request builders.

  This module centralizes all Deribit RPC method definitions
  to avoid duplication across adapter examples.
  """
  @doc """
  Builds a JSON-RPC request for the given method and params.

  ## Parameters
  - `method` - The JSON-RPC method name
  - `params` - Optional parameters map (defaults to empty map)

  ## Returns
  A map containing the complete JSON-RPC request structure.
  """
  @spec build_request(String.t(), map()) :: map()
  def build_request(method, params \\ %{}) do
    %{
      jsonrpc: "2.0",
      id: System.unique_integer([:positive]),
      method: method,
      params: params
    }
  end

  # Authentication & Session

  @doc """
  Builds an authentication request for Deribit API.

  ## Parameters
  - `client_id` - Your Deribit API client ID
  - `client_secret` - Your Deribit API client secret

  ## Returns
  A JSON-RPC request map for authentication.
  """
  @spec auth_request(String.t(), String.t()) :: map()
  def auth_request(client_id, client_secret) do
    build_request("public/auth", %{
      grant_type: "client_credentials",
      client_id: client_id,
      client_secret: client_secret
    })
  end

  @doc """
  Sets the heartbeat interval for the WebSocket connection.

  ## Parameters
  - `interval` - Heartbeat interval in seconds (default: 30)

  ## Returns
  A JSON-RPC request map for setting heartbeat.
  """
  @spec set_heartbeat(integer()) :: map()
  def set_heartbeat(interval \\ 30) do
    build_request("public/set_heartbeat", %{interval: interval})
  end

  @doc """
  Builds a test request to verify the connection is alive.

  ## Returns
  A JSON-RPC request map for connection testing.
  """
  @spec test_request() :: map()
  def test_request do
    build_request("public/test", %{})
  end

  # Subscriptions

  @doc """
  Subscribes to one or more channels for real-time data.

  ## Parameters
  - `channels` - List of channel names to subscribe to

  ## Example
      subscribe(["book.BTC-PERPETUAL.raw", "ticker.ETH-PERPETUAL.raw"])

  ## Returns
  A JSON-RPC request map for subscription.
  """
  @spec subscribe(list(String.t())) :: map()
  def subscribe(channels) when is_list(channels) do
    build_request("public/subscribe", %{channels: channels})
  end

  @doc """
  Unsubscribes from one or more channels.

  ## Parameters
  - `channels` - List of channel names to unsubscribe from

  ## Returns
  A JSON-RPC request map for unsubscription.
  """
  @spec unsubscribe(list(String.t())) :: map()
  def unsubscribe(channels) when is_list(channels) do
    build_request("public/unsubscribe", %{channels: channels})
  end

  # Market Data

  @doc """
  Retrieves available trading instruments for a currency.

  ## Parameters
  - `currency` - Currency code (e.g., "BTC", "ETH")

  ## Returns
  A JSON-RPC request map for retrieving instruments.
  """
  @spec get_instruments(String.t()) :: map()
  def get_instruments(currency) do
    build_request("public/get_instruments", %{currency: currency})
  end

  @doc """
  Retrieves the order book for a specific instrument.

  ## Parameters
  - `instrument` - Instrument name (e.g., "BTC-PERPETUAL")
  - `depth` - Order book depth (default: 10)

  ## Returns
  A JSON-RPC request map for order book data.
  """
  @spec get_order_book(String.t(), integer()) :: map()
  def get_order_book(instrument, depth \\ 10) do
    build_request("public/get_order_book", %{
      instrument_name: instrument,
      depth: depth
    })
  end

  @doc """
  Gets ticker data for a specific instrument.

  ## Parameters
  - `instrument` - Instrument name (e.g., "BTC-PERPETUAL")

  ## Returns
  A JSON-RPC request map for ticker data.
  """
  @spec ticker(String.t()) :: map()
  def ticker(instrument) do
    build_request("public/ticker", %{instrument_name: instrument})
  end

  # Trading (Private)

  @doc """
  Creates a buy order for the specified instrument.

  ## Parameters
  - `instrument` - Instrument name (e.g., "BTC-PERPETUAL")
  - `amount` - Order amount in contracts
  - `opts` - Additional order options (type, price, etc.)

  ## Returns
  A JSON-RPC request map for buy order.
  """
  @spec buy(String.t(), number(), map()) :: map()
  def buy(instrument, amount, opts \\ %{}) do
    params =
      Map.merge(
        %{
          instrument_name: instrument,
          amount: amount
        },
        opts
      )

    build_request("private/buy", params)
  end

  @doc """
  Creates a sell order for the specified instrument.

  ## Parameters
  - `instrument` - Instrument name (e.g., "BTC-PERPETUAL")
  - `amount` - Order amount in contracts
  - `opts` - Additional order options (type, price, etc.)

  ## Returns
  A JSON-RPC request map for sell order.
  """
  @spec sell(String.t(), number(), map()) :: map()
  def sell(instrument, amount, opts \\ %{}) do
    params =
      Map.merge(
        %{
          instrument_name: instrument,
          amount: amount
        },
        opts
      )

    build_request("private/sell", params)
  end

  @doc """
  Cancels an existing order by ID.

  ## Parameters
  - `order_id` - The order ID to cancel

  ## Returns
  A JSON-RPC request map for order cancellation.
  """
  @spec cancel(String.t()) :: map()
  def cancel(order_id) do
    build_request("private/cancel", %{order_id: order_id})
  end

  @doc """
  Retrieves all open orders with optional filters.

  ## Parameters
  - `opts` - Optional filters (instrument, type, etc.)

  ## Returns
  A JSON-RPC request map for retrieving open orders.
  """
  @spec get_open_orders(map()) :: map()
  def get_open_orders(opts \\ %{}) do
    build_request("private/get_open_orders", opts)
  end
end
