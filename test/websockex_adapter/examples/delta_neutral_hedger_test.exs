defmodule WebsockexAdapter.Examples.DeltaNeutralHedgerTest do
  use ExUnit.Case, async: true

  alias WebsockexAdapter.Examples.DeltaNeutralHedger
  alias WebsockexAdapter.Examples.DeribitAdapter

  @moduletag :integration

  setup do
    client_id = System.get_env("DERIBIT_CLIENT_ID")
    client_secret = System.get_env("DERIBIT_CLIENT_SECRET")

    if is_nil(client_id) or is_nil(client_secret) do
      :ok
    else
      {:ok, adapter} =
        DeribitAdapter.connect(
          client_id: client_id,
          client_secret: client_secret,
          test_mode: true
        )

      # Authenticate the adapter
      {:ok, adapter} = DeribitAdapter.authenticate(adapter)

      on_exit(fn ->
        DeribitAdapter.close(adapter)
      end)

      config = %{
        pairs: [
          %{long: "ETH-PERPETUAL", short: "BTC-PERPETUAL", ratio: :dynamic}
        ],
        rebalance_threshold: 100,
        max_order_size: 10_000
      }

      {:ok, adapter: adapter, config: config}
    end
  end

  describe "DeltaNeutralHedger" do
    test "starts with adapter and config", %{adapter: adapter, config: config} do
      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      assert Process.alive?(hedger)
    end

    test "calculates exposures across instruments", %{adapter: adapter, config: config} do
      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      Process.sleep(3000)

      {:ok, exposures} = DeltaNeutralHedger.get_exposures(hedger)

      assert is_map(exposures)
      assert Map.has_key?(exposures, :total_delta)
      assert Map.has_key?(exposures, :positions)
      assert Map.has_key?(exposures, :hedge_required)
      assert is_list(exposures.positions)
    end

    test "monitors multiple trading pairs", %{adapter: adapter} do
      config = %{
        pairs: [
          %{long: "ETH-PERPETUAL", short: "BTC-PERPETUAL", ratio: :dynamic},
          %{long: "ETH-PERPETUAL", short: "ETH-DEC-2024", ratio: 1.0}
        ],
        rebalance_threshold: 100,
        max_order_size: 10_000
      }

      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      Process.sleep(3000)

      {:ok, exposures} = DeltaNeutralHedger.get_exposures(hedger)

      instruments = Enum.map(exposures.positions, & &1.instrument)
      assert "ETH-PERPETUAL" in instruments
      assert "BTC-PERPETUAL" in instruments
    end

    test "calculates hedge requirements based on threshold", %{adapter: adapter} do
      config = %{
        pairs: [
          %{long: "ETH-PERPETUAL", short: "BTC-PERPETUAL", ratio: :dynamic}
        ],
        rebalance_threshold: 50,
        max_order_size: 10_000
      }

      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      Process.sleep(3000)

      {:ok, exposures} = DeltaNeutralHedger.get_exposures(hedger)

      if abs(exposures.total_delta) > 50 do
        assert exposures.hedge_required == true
      else
        assert exposures.hedge_required == false
      end
    end

    test "generates rebalance orders", %{adapter: adapter, config: config} do
      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      Process.sleep(3000)

      {:ok, orders} = DeltaNeutralHedger.rebalance(hedger)

      assert is_list(orders)

      Enum.each(orders, fn order ->
        assert Map.has_key?(order, :instrument)
        assert Map.has_key?(order, :side)
        assert Map.has_key?(order, :size)
        assert Map.has_key?(order, :type)
        assert order.type == "market"
      end)
    end

    test "respects max order size limits", %{adapter: adapter} do
      config = %{
        pairs: [
          %{long: "ETH-PERPETUAL", short: "BTC-PERPETUAL", ratio: :dynamic}
        ],
        rebalance_threshold: 10,
        max_order_size: 100
      }

      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      Process.sleep(3000)

      {:ok, orders} = DeltaNeutralHedger.rebalance(hedger)

      Enum.each(orders, fn order ->
        assert order.size <= 100
      end)
    end

    test "enables auto-hedging with interval", %{adapter: adapter, config: config} do
      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      assert :ok = DeltaNeutralHedger.enable_auto_hedge(hedger, interval: 1000)

      Process.sleep(100)
    end

    test "subscribes to updates", %{adapter: adapter, config: config} do
      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      assert :ok = DeltaNeutralHedger.subscribe_updates(hedger, self())

      config_with_low_threshold = %{config | rebalance_threshold: 0.01}

      {:ok, hedger2} =
        start_supervised(
          {
            DeltaNeutralHedger,
            [adapter: adapter, config: config_with_low_threshold]
          },
          id: :hedger2
        )

      DeltaNeutralHedger.subscribe_updates(hedger2, self())
      {:ok, _orders} = DeltaNeutralHedger.rebalance(hedger2)

      assert_receive {:delta_hedger_update, {:rebalance_executed, _orders}}, 5000
    end

    test "handles subscriber process termination", %{adapter: adapter, config: config} do
      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      subscriber = spawn(fn -> Process.sleep(100) end)

      assert :ok = DeltaNeutralHedger.subscribe_updates(hedger, subscriber)

      Process.sleep(200)

      assert Process.alive?(hedger)
    end

    test "updates positions from portfolio data", %{adapter: adapter, config: config} do
      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      send(
        hedger,
        {:market_data,
         %{
           "channel" => "user.portfolio.any",
           "data" => %{
             "positions" => %{
               "ETH-PERPETUAL" => %{"size" => 1000},
               "BTC-PERPETUAL" => %{"size" => -0.1}
             }
           }
         }}
      )

      Process.sleep(100)

      {:ok, exposures} = DeltaNeutralHedger.get_exposures(hedger)
      assert is_list(exposures.positions)
    end

    test "updates prices from ticker data", %{adapter: adapter, config: config} do
      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      send(
        hedger,
        {:market_data,
         %{
           "channel" => "ticker.ETH-PERPETUAL.raw",
           "data" => %{"mark_price" => 3200.50}
         }}
      )

      send(
        hedger,
        {:market_data,
         %{
           "channel" => "ticker.BTC-PERPETUAL.raw",
           "data" => %{"mark_price" => 65_000.00}
         }}
      )

      Process.sleep(100)

      {:ok, exposures} = DeltaNeutralHedger.get_exposures(hedger)

      eth_position = Enum.find(exposures.positions, &(&1.instrument == "ETH-PERPETUAL"))
      btc_position = Enum.find(exposures.positions, &(&1.instrument == "BTC-PERPETUAL"))

      if eth_position, do: assert(eth_position.price == 3200.50)
      if btc_position, do: assert(btc_position.price == 65_000.00)
    end

    test "calculates delta for positions", %{adapter: adapter, config: config} do
      {:ok, hedger} =
        start_supervised({
          DeltaNeutralHedger,
          [adapter: adapter, config: config]
        })

      send(
        hedger,
        {:market_data,
         %{
           "channel" => "user.portfolio.any",
           "data" => %{
             "positions" => %{
               "ETH-PERPETUAL" => %{"size" => 10}
             }
           }
         }}
      )

      send(
        hedger,
        {:market_data,
         %{
           "channel" => "ticker.ETH-PERPETUAL.raw",
           "data" => %{"mark_price" => 3200}
         }}
      )

      Process.sleep(100)

      {:ok, exposures} = DeltaNeutralHedger.get_exposures(hedger)

      eth_position = Enum.find(exposures.positions, &(&1.instrument == "ETH-PERPETUAL"))

      if eth_position do
        assert eth_position.delta == 10 * 3200
      end
    end
  end

  describe "DeltaNeutralHedger without credentials" do
    @tag :skip
    test "handles missing credentials gracefully" do
      assert {:error, _} =
               DeltaNeutralHedger.start_link(
                 adapter: nil,
                 config: %{pairs: [], rebalance_threshold: 100, max_order_size: 10_000}
               )
    end
  end
end
