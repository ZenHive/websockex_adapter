defmodule WebsockexAdapter.Examples.PositionTracker do
  @moduledoc """
  Real-time position tracking across multiple instruments with P&L and margin monitoring.

  Tracks positions, calculates real-time P&L using mark prices, monitors margin
  requirements and provides liquidation alerts.

  ## Example

      {:ok, tracker} = PositionTracker.start_link(
        adapter: deribit_adapter,
        instruments: ["BTC-PERPETUAL", "ETH-PERPETUAL"]
      )
      
      {:ok, positions} = PositionTracker.get_positions(tracker)
      {:ok, margin} = PositionTracker.get_margin_info(tracker)
  """

  use GenServer

  alias WebsockexAdapter.Examples.DeribitAdapter

  require Logger

  defstruct [
    :adapter,
    :instruments,
    :positions,
    :mark_prices,
    :margin_info,
    :subscribers,
    :refresh_interval
  ]

  # Public API

  @doc """
  Starts the position tracker GenServer.

  ## Options

    * `:adapter` - The Deribit adapter instance (required)
    * `:instruments` - List of instruments to track
    * `:refresh_interval` - Position refresh interval in ms (default: 5000)
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  @doc """
  Get current positions for all tracked instruments.
  """
  @spec get_positions(GenServer.server()) :: {:ok, map()} | {:error, term()}
  def get_positions(tracker) do
    GenServer.call(tracker, :get_positions)
  end

  @doc """
  Get current margin information.
  """
  @spec get_margin_info(GenServer.server()) :: {:ok, map()} | {:error, term()}
  def get_margin_info(tracker) do
    GenServer.call(tracker, :get_margin_info)
  end

  @doc """
  Subscribe to position updates.
  """
  @spec subscribe_updates(GenServer.server(), pid()) :: :ok
  def subscribe_updates(tracker, subscriber) do
    GenServer.cast(tracker, {:subscribe, subscriber})
  end

  @doc """
  Add instruments to track.
  """
  @spec add_instruments(GenServer.server(), list(String.t())) :: :ok
  def add_instruments(tracker, instruments) do
    GenServer.cast(tracker, {:add_instruments, instruments})
  end

  # GenServer implementation

  @impl true
  def init(opts) do
    adapter = Keyword.fetch!(opts, :adapter)
    instruments = Keyword.get(opts, :instruments, [])
    refresh_interval = Keyword.get(opts, :refresh_interval, 5000)

    state = %__MODULE__{
      adapter: adapter,
      instruments: instruments,
      positions: %{},
      mark_prices: %{},
      margin_info: %{},
      subscribers: [],
      refresh_interval: refresh_interval
    }

    # Subscribe to position and price updates
    if instruments != [] do
      subscribe_to_updates(state)
    end

    # Schedule periodic position refresh
    schedule_refresh(refresh_interval)

    {:ok, state}
  end

  @impl true
  def handle_call(:get_positions, _from, state) do
    positions = calculate_current_positions(state)
    {:reply, {:ok, positions}, state}
  end

  @impl true
  def handle_call(:get_margin_info, _from, state) do
    {:reply, {:ok, state.margin_info}, state}
  end

  @impl true
  def handle_cast({:subscribe, subscriber}, state) do
    Process.monitor(subscriber)
    {:noreply, %{state | subscribers: [subscriber | state.subscribers]}}
  end

  @impl true
  def handle_cast({:add_instruments, new_instruments}, state) do
    instruments = Enum.uniq(state.instruments ++ new_instruments)
    state = %{state | instruments: instruments}

    # Subscribe to new instruments
    subscribe_to_updates(state)

    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh_positions, state) do
    state = refresh_all_positions(state)
    schedule_refresh(state.refresh_interval)
    {:noreply, state}
  end

  @impl true
  def handle_info({:websocket_message, %{"method" => "subscription", "params" => params}}, state) do
    state = handle_subscription_update(params, state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    subscribers = Enum.reject(state.subscribers, &(&1 == pid))
    {:noreply, %{state | subscribers: subscribers}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private functions

  defp subscribe_to_updates(%{adapter: adapter, instruments: instruments}) do
    # Subscribe to position changes
    channels = ["user.changes.any.any.raw"]

    # Subscribe to mark price updates for each instrument
    price_channels = Enum.map(instruments, &"ticker.#{&1}.raw")

    DeribitAdapter.subscribe(adapter, channels ++ price_channels)
  end

  defp schedule_refresh(interval) do
    Process.send_after(self(), :refresh_positions, interval)
  end

  defp refresh_all_positions(state) do
    # Get current positions
    case DeribitAdapter.send_request(state.adapter, "private/get_positions", %{currency: "BTC", kind: "future"}) do
      {:ok, %{"result" => positions}} ->
        state = update_positions(positions, state)

        # Get account summary for margin info
        case DeribitAdapter.send_request(state.adapter, "private/get_account_summary", %{currency: "BTC"}) do
          {:ok, %{"result" => summary}} ->
            margin_info = extract_margin_info(summary)
            notify_subscribers({:margin_update, margin_info}, state)
            %{state | margin_info: margin_info}

          _ ->
            state
        end

      _ ->
        state
    end
  end

  defp handle_subscription_update(%{"channel" => channel, "data" => data}, state) do
    cond do
      String.starts_with?(channel, "ticker.") ->
        instrument = extract_instrument_from_channel(channel)
        mark_price = data["mark_price"]

        state = %{state | mark_prices: Map.put(state.mark_prices, instrument, mark_price)}

        # Notify subscribers of price update
        if Map.has_key?(state.positions, instrument) do
          positions = calculate_current_positions(state)
          notify_subscribers({:position_update, positions}, state)
        end

        state

      channel == "user.changes.any.any.raw" ->
        handle_user_changes(data, state)

      true ->
        state
    end
  end

  defp handle_user_changes(data, state) do
    # Update positions if present
    state =
      if data["positions"] do
        update_positions(data["positions"], state)
      else
        state
      end

    # Update trades if present  
    if data["trades"] do
      positions = calculate_current_positions(state)
      notify_subscribers({:position_update, positions}, state)
    end

    state
  end

  defp update_positions(positions, state) do
    position_map =
      positions
      |> Enum.filter(&(&1["size"] != 0))
      |> Map.new(fn pos ->
        {pos["instrument_name"],
         %{
           size: pos["size"],
           avg_price: pos["average_price"],
           realized_pnl: pos["realized_profit_loss"],
           floating_pnl: pos["floating_profit_loss"]
         }}
      end)

    %{state | positions: position_map}
  end

  defp calculate_current_positions(state) do
    Map.new(state.positions, fn {instrument, pos} ->
      mark_price = Map.get(state.mark_prices, instrument, pos.avg_price)
      # Calculate unrealized P&L
      pnl =
        if pos.size > 0 do
          pos.size * (mark_price - pos.avg_price)
        else
          pos.size * (pos.avg_price - mark_price)
        end

      {instrument,
       Map.merge(pos, %{
         mark_price: mark_price,
         pnl: pnl,
         total_pnl: pos.realized_pnl + pnl
       })}
    end)
  end

  defp extract_margin_info(summary) do
    %{
      balance: summary["balance"],
      equity: summary["equity"],
      margin: summary["margin_balance"],
      initial_margin: summary["initial_margin"],
      maintenance_margin: summary["maintenance_margin"],
      available_funds: summary["available_funds"],
      liquidation_price: calculate_liquidation_price(summary)
    }
  end

  defp calculate_liquidation_price(summary) do
    # Simplified liquidation price calculation
    if summary["maintenance_margin"] > 0 do
      margin_ratio = summary["equity"] / summary["maintenance_margin"]

      cond do
        margin_ratio < 1.5 -> :high_risk
        margin_ratio < 2.0 -> :medium_risk
        true -> :low_risk
      end
    else
      :no_position
    end
  end

  defp extract_instrument_from_channel(channel) do
    channel
    |> String.split(".")
    |> Enum.at(1)
  end

  defp notify_subscribers(message, state) do
    Enum.each(state.subscribers, fn subscriber ->
      send(subscriber, {:position_tracker, message})
    end)
  end
end
