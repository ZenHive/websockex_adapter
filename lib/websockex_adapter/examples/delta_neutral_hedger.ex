defmodule WebsockexAdapter.Examples.DeltaNeutralHedger do
  @moduledoc """
  Delta-neutral hedging for maintaining dollar-neutral positions across multiple assets.

  Monitors positions, calculates exposures, and executes hedge trades automatically.
  Supports ETH/BTC pairs, perpetual/spot arbitrage, and other delta-neutral strategies.
  """

  use GenServer

  alias WebsockexAdapter.Examples.DeribitAdapter

  require Logger

  @type pair :: %{
          long: String.t(),
          short: String.t(),
          ratio: float() | :dynamic
        }

  @type config :: %{
          pairs: [pair()],
          rebalance_threshold: float(),
          max_order_size: float()
        }

  @type state :: %{
          adapter: pid(),
          config: config(),
          positions: map(),
          prices: map(),
          auto_hedge: boolean(),
          auto_hedge_ref: reference() | nil,
          subscribers: MapSet.t()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec get_exposures(pid()) :: {:ok, map()} | {:error, term()}
  def get_exposures(hedger) do
    GenServer.call(hedger, :get_exposures)
  end

  @spec rebalance(pid()) :: {:ok, list()} | {:error, term()}
  def rebalance(hedger) do
    GenServer.call(hedger, :rebalance)
  end

  @spec enable_auto_hedge(pid(), keyword()) :: :ok
  def enable_auto_hedge(hedger, opts \\ []) do
    GenServer.cast(hedger, {:enable_auto_hedge, opts})
  end

  @spec subscribe_updates(pid(), pid()) :: :ok
  def subscribe_updates(hedger, subscriber) do
    GenServer.cast(hedger, {:subscribe, subscriber})
  end

  ## GenServer Callbacks

  @impl true
  def init(opts) do
    adapter = Keyword.fetch!(opts, :adapter)
    config = Keyword.fetch!(opts, :config)

    state = %{
      adapter: adapter,
      config: config,
      positions: %{},
      prices: %{},
      auto_hedge: false,
      auto_hedge_ref: nil,
      subscribers: MapSet.new()
    }

    instruments = extract_instruments(config.pairs)
    setup_subscriptions(adapter, instruments)

    {:ok, state}
  end

  @impl true
  def handle_call(:get_exposures, _from, state) do
    exposures = calculate_exposures(state)
    {:reply, {:ok, exposures}, state}
  end

  @impl true
  def handle_call(:rebalance, _from, state) do
    case execute_rebalance(state) do
      {:ok, orders} = result ->
        notify_subscribers(state, {:rebalance_executed, orders})
        {:reply, result, state}

      error ->
        {:reply, error, state}
    end
  end

  @impl true
  def handle_cast({:enable_auto_hedge, opts}, state) do
    interval = Keyword.get(opts, :interval, 5000)
    ref = Process.send_after(self(), :auto_hedge_check, interval)

    {:noreply, %{state | auto_hedge: true, auto_hedge_ref: ref}}
  end

  @impl true
  def handle_cast({:subscribe, subscriber}, state) do
    Process.monitor(subscriber)
    subscribers = MapSet.put(state.subscribers, subscriber)
    {:noreply, %{state | subscribers: subscribers}}
  end

  @impl true
  def handle_info({:market_data, %{"channel" => channel, "data" => data}}, state) do
    state = update_market_data(state, channel, data)
    {:noreply, state}
  end

  @impl true
  def handle_info(:auto_hedge_check, %{auto_hedge: true} = state) do
    exposures = calculate_exposures(state)

    if abs(exposures.total_delta) > state.config.rebalance_threshold do
      execute_rebalance(state)
      notify_subscribers(state, {:auto_hedge_triggered, exposures})
    end

    interval = 5000
    ref = Process.send_after(self(), :auto_hedge_check, interval)
    {:noreply, %{state | auto_hedge_ref: ref}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    subscribers = MapSet.delete(state.subscribers, pid)
    {:noreply, %{state | subscribers: subscribers}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ## Private Functions

  defp extract_instruments(pairs) do
    pairs
    |> Enum.flat_map(fn pair ->
      [pair.long, pair.short]
    end)
    |> Enum.uniq()
  end

  defp setup_subscriptions(adapter, instruments) do
    Enum.each(instruments, fn instrument ->
      channels = [
        "ticker.#{instrument}.raw",
        "user.portfolio.any"
      ]

      DeribitAdapter.subscribe(adapter, channels)
    end)
  end

  defp calculate_exposures(state) do
    positions =
      state.config.pairs
      |> Enum.map(fn pair ->
        long_pos = get_position(state, pair.long)
        short_pos = get_position(state, pair.short)

        long_delta = calculate_delta(long_pos, get_price(state, pair.long))
        short_delta = calculate_delta(short_pos, get_price(state, pair.short))

        [
          %{instrument: pair.long, delta: long_delta, price: get_price(state, pair.long)},
          %{instrument: pair.short, delta: short_delta, price: get_price(state, pair.short)}
        ]
      end)
      |> List.flatten()
      |> Enum.uniq_by(& &1.instrument)

    total_delta = Enum.reduce(positions, 0, &(&1.delta + &2))

    %{
      total_delta: total_delta,
      positions: positions,
      hedge_required: abs(total_delta) > state.config.rebalance_threshold
    }
  end

  defp execute_rebalance(state) do
    exposures = calculate_exposures(state)

    if exposures.hedge_required do
      orders = calculate_hedge_orders(state, exposures)
      {:ok, orders}
    else
      {:ok, []}
    end
  end

  defp calculate_hedge_orders(state, exposures) do
    target_delta = -exposures.total_delta

    state.config.pairs
    |> Enum.take(1)
    |> Enum.map(fn pair ->
      instrument = if target_delta > 0, do: pair.long, else: pair.short
      side = if target_delta > 0, do: "buy", else: "sell"
      size = min(abs(target_delta), state.config.max_order_size)

      %{
        instrument: instrument,
        side: side,
        size: size,
        type: "market"
      }
    end)
  end

  defp update_market_data(state, channel, data) do
    cond do
      String.starts_with?(channel, "ticker.") ->
        instrument = parse_instrument_from_channel(channel)
        price = data["mark_price"] || data["last_price"]
        put_in(state, [:prices, instrument], price)

      channel == "user.portfolio.any" ->
        update_positions(state, data)

      true ->
        state
    end
  end

  defp parse_instrument_from_channel(channel) do
    channel
    |> String.split(".")
    |> Enum.at(1)
  end

  defp update_positions(state, portfolio_data) do
    positions = Map.get(portfolio_data, "positions", %{})
    %{state | positions: positions}
  end

  defp get_position(state, instrument) do
    Map.get(state.positions, instrument, %{"size" => 0})
  end

  defp get_price(state, instrument) do
    Map.get(state.prices, instrument, 0)
  end

  defp calculate_delta(position, price) do
    size = Map.get(position, "size", 0)
    size * price
  end

  defp notify_subscribers(state, message) do
    Enum.each(state.subscribers, fn subscriber ->
      send(subscriber, {:delta_hedger_update, message})
    end)
  end
end
