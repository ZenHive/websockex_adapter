defmodule WebsockexAdapter.Examples.DeribitRpc do
  @moduledoc """
  Shared Deribit JSON-RPC method definitions and request builders.
  
  This module centralizes all Deribit RPC method definitions
  to avoid duplication across adapter examples.
  """

  @doc """
  Builds a JSON-RPC request for the given method and params.
  """
  def build_request(method, params \\ %{}) do
    %{
      jsonrpc: "2.0",
      id: System.unique_integer([:positive]),
      method: method,
      params: params
    }
  end

  # Authentication & Session
  def auth_request(client_id, client_secret) do
    build_request("public/auth", %{
      grant_type: "client_credentials",
      client_id: client_id,
      client_secret: client_secret
    })
  end

  def set_heartbeat(interval \\ 30) do
    build_request("public/set_heartbeat", %{interval: interval})
  end

  def test_request do
    build_request("public/test", %{})
  end

  # Subscriptions
  def subscribe(channels) when is_list(channels) do
    build_request("public/subscribe", %{channels: channels})
  end

  def unsubscribe(channels) when is_list(channels) do
    build_request("public/unsubscribe", %{channels: channels})
  end

  # Market Data
  def get_instruments(currency) do
    build_request("public/get_instruments", %{currency: currency})
  end

  def get_order_book(instrument, depth \\ 10) do
    build_request("public/get_order_book", %{
      instrument_name: instrument,
      depth: depth
    })
  end

  def ticker(instrument) do
    build_request("public/ticker", %{instrument_name: instrument})
  end

  # Trading (Private)
  def buy(instrument, amount, opts \\ %{}) do
    params = Map.merge(%{
      instrument_name: instrument,
      amount: amount
    }, opts)
    build_request("private/buy", params)
  end

  def sell(instrument, amount, opts \\ %{}) do
    params = Map.merge(%{
      instrument_name: instrument,
      amount: amount
    }, opts)
    build_request("private/sell", params)
  end

  def cancel(order_id) do
    build_request("private/cancel", %{order_id: order_id})
  end

  def get_open_orders(opts \\ %{}) do
    build_request("private/get_open_orders", opts)
  end
end