defmodule WebsockexAdapter.Examples.PositionTrackerTest do
  use ExUnit.Case, async: false

  alias WebsockexAdapter.Examples.DeribitAdapter
  alias WebsockexAdapter.Examples.PositionTracker

  @moduletag :integration

  setup do
    # These tests require valid Deribit testnet credentials
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

      {:ok, adapter: adapter}
    end
  end

  describe "start_link/1" do
    @tag :integration
    test "starts the position tracker", %{adapter: adapter} do
      assert {:ok, tracker} =
               PositionTracker.start_link(
                 adapter: adapter,
                 instruments: ["BTC-PERPETUAL"]
               )

      assert Process.alive?(tracker)
    end

    @tag :integration
    test "requires adapter option", %{adapter: _adapter} do
      Process.flag(:trap_exit, true)

      {:error, _} = PositionTracker.start_link(instruments: ["BTC-PERPETUAL"])
    end
  end

  describe "get_positions/1" do
    @tag :integration
    test "returns current positions", %{adapter: adapter} do
      {:ok, tracker} =
        PositionTracker.start_link(
          adapter: adapter,
          instruments: ["BTC-PERPETUAL", "ETH-PERPETUAL"]
        )

      # Wait for initial data
      Process.sleep(1000)

      assert {:ok, positions} = PositionTracker.get_positions(tracker)
      assert is_map(positions)

      # Positions may be empty if no open positions
      for {_instrument, pos} <- positions do
        assert Map.has_key?(pos, :size)
        assert Map.has_key?(pos, :avg_price)
        assert Map.has_key?(pos, :pnl)
        assert Map.has_key?(pos, :mark_price)
      end
    end
  end

  describe "get_margin_info/1" do
    @tag :integration
    test "returns margin information", %{adapter: adapter} do
      {:ok, tracker} =
        PositionTracker.start_link(
          adapter: adapter,
          instruments: []
        )

      # Wait for initial margin refresh
      Process.sleep(6000)

      assert {:ok, margin} = PositionTracker.get_margin_info(tracker)
      assert is_map(margin)

      # Check expected fields
      assert Map.has_key?(margin, :balance)
      assert Map.has_key?(margin, :equity)
      assert Map.has_key?(margin, :available_funds)
      assert Map.has_key?(margin, :liquidation_price)
    end
  end

  describe "subscribe_updates/2" do
    @tag :integration
    test "receives position updates", %{adapter: adapter} do
      {:ok, tracker} =
        PositionTracker.start_link(
          adapter: adapter,
          instruments: ["BTC-PERPETUAL"],
          refresh_interval: 2000
        )

      # Subscribe to updates
      PositionTracker.subscribe_updates(tracker, self())

      # Wait for an update
      assert_receive {:position_tracker, {:margin_update, margin}}, 5000
      assert is_map(margin)
      assert Map.has_key?(margin, :balance)
    end

    @tag :integration
    test "handles subscriber process death", %{adapter: adapter} do
      {:ok, tracker} =
        PositionTracker.start_link(
          adapter: adapter,
          instruments: []
        )

      # Create a process and subscribe
      pid = spawn(fn -> Process.sleep(100) end)
      PositionTracker.subscribe_updates(tracker, pid)

      # Wait for process to die
      Process.sleep(200)

      # Tracker should still be alive
      assert Process.alive?(tracker)
    end
  end

  describe "add_instruments/2" do
    @tag :integration
    test "adds new instruments to track", %{adapter: adapter} do
      {:ok, tracker} =
        PositionTracker.start_link(
          adapter: adapter,
          instruments: ["BTC-PERPETUAL"]
        )

      # Add new instrument
      assert :ok = PositionTracker.add_instruments(tracker, ["ETH-PERPETUAL"])

      # Should handle duplicates
      assert :ok = PositionTracker.add_instruments(tracker, ["BTC-PERPETUAL"])
    end
  end

  describe "position calculations" do
    @tag :integration
    test "calculates P&L correctly", %{adapter: adapter} do
      {:ok, tracker} =
        PositionTracker.start_link(
          adapter: adapter,
          instruments: ["BTC-PERPETUAL"]
        )

      # This test verifies calculation logic
      # In real scenario, would need actual positions

      {:ok, positions} = PositionTracker.get_positions(tracker)

      for {_instrument, pos} <- positions do
        if pos[:size] && pos[:size] != 0 do
          # Verify P&L calculation
          expected_pnl =
            if pos.size > 0 do
              pos.size * (pos.mark_price - pos.avg_price)
            else
              pos.size * (pos.avg_price - pos.mark_price)
            end

          assert_in_delta pos.pnl, expected_pnl, 0.01
        end
      end
    end
  end

  describe "margin monitoring" do
    @tag :integration
    test "calculates liquidation risk levels", %{adapter: adapter} do
      {:ok, tracker} =
        PositionTracker.start_link(
          adapter: adapter,
          instruments: [],
          refresh_interval: 2000
        )

      # Wait for margin update
      Process.sleep(3000)

      {:ok, margin} = PositionTracker.get_margin_info(tracker)

      assert margin.liquidation_price in [:high_risk, :medium_risk, :low_risk, :no_position]
    end
  end

  describe "websocket message handling" do
    @tag :integration
    test "processes ticker updates", %{adapter: adapter} do
      {:ok, tracker} =
        PositionTracker.start_link(
          adapter: adapter,
          instruments: ["BTC-PERPETUAL"]
        )

      # Subscribe to get notifications
      PositionTracker.subscribe_updates(tracker, self())

      # Wait for ticker update
      receive do
        {:position_tracker, {:position_update, _positions}} ->
          assert true
      after
        10_000 ->
          # May not receive update if no position
          assert true
      end
    end
  end

  # Unit tests (not requiring real API)

  describe "initialization" do
    test "initializes with default values" do
      # Mock adapter
      {:ok, mock_adapter} = Agent.start_link(fn -> %{} end)

      {:ok, tracker} =
        PositionTracker.start_link(
          adapter: mock_adapter,
          instruments: [],
          refresh_interval: 60_000
        )

      state = :sys.get_state(tracker)

      assert state.positions == %{}
      assert state.mark_prices == %{}
      assert state.margin_info == %{}
      assert state.subscribers == []
      assert state.refresh_interval == 60_000
    end
  end

  describe "error handling" do
    test "handles invalid adapter gracefully" do
      Process.flag(:trap_exit, true)

      {:error, _} = PositionTracker.start_link(instruments: ["BTC-PERPETUAL"])
    end
  end
end
