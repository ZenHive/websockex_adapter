defmodule DeribitApi.Trading do
  @moduledoc """
  Trading endpoints for the Deribit API.

  The Deribit API documentation is the single source of truth:
  https://docs.deribit.com/#trading
  """

  @type params :: map()
  @type result :: {:ok, map()} | {:error, any()}

  @endpoints [
    buy: "https://docs.deribit.com/#private-buy",
    sell: "https://docs.deribit.com/#private-sell",
    edit: "https://docs.deribit.com/#private-edit",
    edit_by_label: "https://docs.deribit.com/#private-edit_by_label",
    cancel: "https://docs.deribit.com/#private-cancel",
    cancel_all: "https://docs.deribit.com/#private-cancel_all",
    cancel_all_by_currency: "https://docs.deribit.com/#private-cancel_all_by_currency",
    cancel_all_by_instrument: "https://docs.deribit.com/#private-cancel_all_by_instrument",
    cancel_all_by_kind_or_type: "https://docs.deribit.com/#private-cancel_all_by_kind_or_type",
    cancel_by_label: "https://docs.deribit.com/#private-cancel_by_label",
    close_position: "https://docs.deribit.com/#private-close_position",
    get_mmp_config: "https://docs.deribit.com/#private-get_mmp_config",
    get_mmp_status: "https://docs.deribit.com/#private-get_mmp_status",
    get_open_orders: "https://docs.deribit.com/#private-get_open_orders",
    get_open_orders_by_currency: "https://docs.deribit.com/#private-get_open_orders_by_currency",
    get_open_orders_by_instrument: "https://docs.deribit.com/#private-get_open_orders_by_instrument",
    get_order_history_by_currency: "https://docs.deribit.com/#private-get_order_history_by_currency",
    get_order_history_by_instrument: "https://docs.deribit.com/#private-get_order_history_by_instrument",
    get_user_trades_by_currency: "https://docs.deribit.com/#private-get_user_trades_by_currency",
    get_user_trades_by_currency_and_time: "https://docs.deribit.com/#private-get_user_trades_by_currency_and_time",
    get_settlement_history_by_currency: "https://docs.deribit.com/#private-get_settlement_history_by_currency"
  ]

  for {name, url} <- @endpoints do
    @doc """
    See: #{url}
    """
    @spec unquote(name)(params(), (any() -> any())) :: result()
    def unquote(name)(params \\ %{}, f) do
      DeribitApi.API.WebSockets.get_private(
        unquote(to_string(name)),
        client_id(),
        client_secret(),
        params,
        f
      )
    end
  end

  def client_id, do: Application.get_env(:deribit_api, :client_id)
  def client_secret, do: Application.get_env(:deribit_api, :client_secret)
end
