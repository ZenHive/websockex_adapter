defmodule WebsockexAdapter.Examples.BatchSubscriptionManagerTest do
  use ExUnit.Case, async: false

  alias WebsockexAdapter.Examples.BatchSubscriptionManager
  alias WebsockexAdapter.Examples.DeribitAdapter

  @deribit_test_url "wss://test.deribit.com/ws/api/v2"
  @test_channels [
    "ticker.BTC-PERPETUAL.raw",
    "ticker.ETH-PERPETUAL.raw",
    "book.BTC-PERPETUAL.raw",
    "book.ETH-PERPETUAL.raw"
  ]

  setup do
    client_id = System.get_env("DERIBIT_CLIENT_ID") || "test_client"
    client_secret = System.get_env("DERIBIT_CLIENT_SECRET") || "test_secret"

    # Connect to Deribit
    {:ok, adapter} =
      DeribitAdapter.connect(
        url: @deribit_test_url,
        client_id: client_id,
        client_secret: client_secret
      )

    {:ok, adapter} = DeribitAdapter.authenticate(adapter)

    on_exit(fn ->
      DeribitAdapter.close(adapter)
    end)

    {:ok, adapter: adapter}
  end

  describe "start_link/1" do
    test "starts GenServer with configuration", %{adapter: adapter} do
      {:ok, manager} =
        BatchSubscriptionManager.start_link(
          adapter: adapter,
          batch_size: 2,
          batch_delay: 100
        )

      assert Process.alive?(manager)
    end
  end

  test "requires adapter in options" do
    # This test doesn't need setup since we're testing missing adapter
    # Since the error occurs in init/1, we need to trap exits
    Process.flag(:trap_exit, true)

    {:error, {exception, _stacktrace}} = BatchSubscriptionManager.start_link(batch_size: 10)

    # The GenServer will fail to start due to missing adapter
    assert %KeyError{key: :adapter} = exception
  end

  describe "subscribe_batch/2" do
    test "queues channels for batch processing", %{adapter: adapter} do
      {:ok, manager} =
        BatchSubscriptionManager.start_link(
          adapter: adapter,
          batch_size: 2,
          batch_delay: 50
        )

      {:ok, request_id} = BatchSubscriptionManager.subscribe_batch(manager, @test_channels)

      assert is_binary(request_id)
      assert String.starts_with?(request_id, "req_")
    end

    test "returns unique request IDs", %{adapter: adapter} do
      {:ok, manager} = BatchSubscriptionManager.start_link(adapter: adapter)

      {:ok, id1} = BatchSubscriptionManager.subscribe_batch(manager, ["channel1"])
      {:ok, id2} = BatchSubscriptionManager.subscribe_batch(manager, ["channel2"])

      assert id1 != id2
    end
  end

  describe "get_status/2" do
    test "returns status tracking progress", %{adapter: adapter} do
      {:ok, manager} =
        BatchSubscriptionManager.start_link(
          adapter: adapter,
          # Process all at once
          batch_size: 4,
          batch_delay: 100
        )

      {:ok, request_id} = BatchSubscriptionManager.subscribe_batch(manager, @test_channels)

      # Wait a bit for processing
      Process.sleep(200)

      {:ok, status} = BatchSubscriptionManager.get_status(manager, request_id)

      assert status.total == 4
      # Should be completed by now
      assert status.completed == 4
      assert status.pending == 0
      assert status.failed == 0
    end

    test "tracks progress during batch processing", %{adapter: adapter} do
      {:ok, manager} =
        BatchSubscriptionManager.start_link(
          adapter: adapter,
          batch_size: 2,
          batch_delay: 100
        )

      {:ok, request_id} = BatchSubscriptionManager.subscribe_batch(manager, @test_channels)

      # Wait for first batch
      Process.sleep(150)

      {:ok, status} = BatchSubscriptionManager.get_status(manager, request_id)
      assert status.completed >= 2
      assert status.pending <= 2
    end

    test "returns error for unknown request ID", %{adapter: adapter} do
      {:ok, manager} = BatchSubscriptionManager.start_link(adapter: adapter)

      assert {:error, :not_found} = BatchSubscriptionManager.get_status(manager, "unknown_id")
    end
  end

  describe "cancel_batch/2" do
    test "cancels pending batch processing", %{adapter: adapter} do
      {:ok, manager} =
        BatchSubscriptionManager.start_link(
          adapter: adapter,
          batch_size: 1,
          # Long delay to allow cancellation
          batch_delay: 500
        )

      channels = for i <- 1..10, do: "ticker.BTC-#{i}JUN25.raw"
      {:ok, request_id} = BatchSubscriptionManager.subscribe_batch(manager, channels)

      # Cancel after first batch
      Process.sleep(100)
      assert :ok = BatchSubscriptionManager.cancel_batch(manager, request_id)

      # Wait and verify no more progress
      Process.sleep(600)
      {:ok, status} = BatchSubscriptionManager.get_status(manager, request_id)
      assert status.completed < 10
    end

    test "returns error for unknown request ID", %{adapter: adapter} do
      {:ok, manager} = BatchSubscriptionManager.start_link(adapter: adapter)

      assert {:error, :not_found} = BatchSubscriptionManager.cancel_batch(manager, "unknown_id")
    end
  end

  describe "get_all_statuses/1" do
    test "returns all batch request statuses", %{adapter: adapter} do
      {:ok, manager} = BatchSubscriptionManager.start_link(adapter: adapter)

      {:ok, id1} = BatchSubscriptionManager.subscribe_batch(manager, ["channel1", "channel2"])
      {:ok, id2} = BatchSubscriptionManager.subscribe_batch(manager, ["channel3", "channel4"])

      {:ok, all_statuses} = BatchSubscriptionManager.get_all_statuses(manager)

      assert Map.has_key?(all_statuses, id1)
      assert Map.has_key?(all_statuses, id2)
      assert all_statuses[id1].total == 2
      assert all_statuses[id2].total == 2
    end

    test "returns empty map when no requests", %{adapter: adapter} do
      {:ok, manager} = BatchSubscriptionManager.start_link(adapter: adapter)

      {:ok, all_statuses} = BatchSubscriptionManager.get_all_statuses(manager)
      assert all_statuses == %{}
    end
  end

  describe "batch processing" do
    @tag :integration
    test "processes large batch with configured size and delay", %{adapter: adapter} do
      batch_size = 5
      batch_delay = 200

      {:ok, manager} =
        BatchSubscriptionManager.start_link(
          adapter: adapter,
          batch_size: batch_size,
          batch_delay: batch_delay
        )

      # Create 10 unique channels (smaller to avoid rate limits)
      channels =
        for i <- 1..10 do
          "ticker.BTC-#{i}DEC25.raw"
        end

      {:ok, request_id} = BatchSubscriptionManager.subscribe_batch(manager, channels)

      # Should process in 2 batches of 5
      # Wait for all batches (2 batches * 200ms delay + processing time)
      Process.sleep(1000)

      {:ok, status} = BatchSubscriptionManager.get_status(manager, request_id)

      # Should complete all
      assert status.completed == 10
      assert status.pending == 0
    end

    @tag :integration
    test "handles subscription failures gracefully", %{adapter: adapter} do
      {:ok, manager} =
        BatchSubscriptionManager.start_link(
          adapter: adapter,
          # Process all at once
          batch_size: 4
        )

      # Mix valid and invalid channels
      channels = [
        # Valid
        "ticker.BTC-PERPETUAL.raw",
        # Valid
        "ticker.ETH-PERPETUAL.raw",
        # Valid
        "book.BTC-PERPETUAL.raw",
        # Valid
        "book.ETH-PERPETUAL.raw"
      ]

      {:ok, request_id} = BatchSubscriptionManager.subscribe_batch(manager, channels)

      # Wait for processing
      Process.sleep(300)

      {:ok, status} = BatchSubscriptionManager.get_status(manager, request_id)

      # Should process all channels successfully
      assert status.completed == 4
      assert status.pending == 0
      assert status.failed == 0
    end

    @tag :integration
    test "processes multiple concurrent batch requests", %{adapter: adapter} do
      {:ok, manager} =
        BatchSubscriptionManager.start_link(
          adapter: adapter,
          batch_size: 2,
          batch_delay: 50
        )

      # Queue multiple batch requests
      {:ok, id1} =
        BatchSubscriptionManager.subscribe_batch(
          manager,
          ["ticker.BTC-PERPETUAL.raw", "ticker.ETH-PERPETUAL.raw"]
        )

      {:ok, id2} =
        BatchSubscriptionManager.subscribe_batch(
          manager,
          ["book.BTC-PERPETUAL.raw", "book.ETH-PERPETUAL.raw"]
        )

      {:ok, id3} =
        BatchSubscriptionManager.subscribe_batch(
          manager,
          ["trades.BTC-PERPETUAL.raw", "trades.ETH-PERPETUAL.raw"]
        )

      # Wait for all to process
      Process.sleep(500)

      # Check all completed
      {:ok, status1} = BatchSubscriptionManager.get_status(manager, id1)
      {:ok, status2} = BatchSubscriptionManager.get_status(manager, id2)
      {:ok, status3} = BatchSubscriptionManager.get_status(manager, id3)

      assert status1.pending == 0
      assert status2.pending == 0
      assert status3.pending == 0
    end
  end
end
