defmodule WebsockexAdapter.Examples.DeribitGenServerAdapterTest do
  use ExUnit.Case

  alias WebsockexAdapter.Examples.DeribitGenServerAdapter

  require Logger

  @moduletag :integration

  setup do
    # Start the ClientSupervisor for testing
    start_supervised!(WebsockexAdapter.ClientSupervisor)
    :ok
  end

  describe "fault tolerance" do
    test "adapter reconnects when Client GenServer dies" do
      # Start adapter with no credentials (won't authenticate)
      {:ok, adapter} =
        DeribitGenServerAdapter.start_link(
          client_id: nil,
          client_secret: nil,
          heartbeat_interval: 1
        )

      # Get initial state
      {:ok, initial_state} = DeribitGenServerAdapter.get_state(adapter)
      assert initial_state.client != nil
      initial_pid = initial_state.client.server_pid

      # Monitor the adapter to ensure it doesn't die
      adapter_ref = Process.monitor(adapter)

      # Kill the Client GenServer
      Process.exit(initial_pid, :kill)

      # Give it time to reconnect
      Process.sleep(100)

      # Adapter should still be alive
      refute_receive {:DOWN, ^adapter_ref, :process, ^adapter, _}

      # Check new state
      {:ok, new_state} = DeribitGenServerAdapter.get_state(adapter)
      assert new_state.client != nil
      assert new_state.client.server_pid != initial_pid
    end

    @tag :requires_credentials
    test "adapter restores authentication after Client death" do
      client_id = System.get_env("DERIBIT_CLIENT_ID")
      client_secret = System.get_env("DERIBIT_CLIENT_SECRET")

      # Testing policy: No skips allowed - let tests fail if credentials missing
      assert client_id != nil, "DERIBIT_CLIENT_ID environment variable must be set"
      assert client_secret != nil, "DERIBIT_CLIENT_SECRET environment variable must be set"

      {:ok, adapter} =
        DeribitGenServerAdapter.start_link(
          client_id: client_id,
          client_secret: client_secret,
          heartbeat_interval: 1
        )

      # Authenticate
      :ok = DeribitGenServerAdapter.authenticate(adapter)

      {:ok, auth_state} = DeribitGenServerAdapter.get_state(adapter)
      assert auth_state.authenticated == true
      initial_pid = auth_state.client.server_pid

      # Kill the Client GenServer
      Process.exit(initial_pid, :kill)

      # Wait for reconnection and re-authentication
      Process.sleep(2000)

      # Check authentication was restored
      {:ok, new_state} = DeribitGenServerAdapter.get_state(adapter)
      assert new_state.authenticated == true
      assert new_state.client.server_pid != initial_pid
    end

    @tag :requires_credentials
    test "adapter restores subscriptions after Client death" do
      client_id = System.get_env("DERIBIT_CLIENT_ID")
      client_secret = System.get_env("DERIBIT_CLIENT_SECRET")

      # Testing policy: No skips allowed - let tests fail if credentials missing
      assert client_id != nil, "DERIBIT_CLIENT_ID environment variable must be set"
      assert client_secret != nil, "DERIBIT_CLIENT_SECRET environment variable must be set"

      {:ok, adapter} =
        DeribitGenServerAdapter.start_link(
          client_id: client_id,
          client_secret: client_secret,
          heartbeat_interval: 1
        )

      # Authenticate and subscribe
      :ok = DeribitGenServerAdapter.authenticate(adapter)
      :ok = DeribitGenServerAdapter.subscribe(adapter, ["ticker.BTC-PERPETUAL.raw"])

      {:ok, sub_state} = DeribitGenServerAdapter.get_state(adapter)
      assert MapSet.member?(sub_state.subscriptions, "ticker.BTC-PERPETUAL.raw")
      initial_pid = sub_state.client.server_pid

      # Kill the Client GenServer
      Process.exit(initial_pid, :kill)

      # Wait for full restoration
      Process.sleep(3000)

      # Check subscriptions were restored
      {:ok, new_state} = DeribitGenServerAdapter.get_state(adapter)
      assert new_state.authenticated == true
      assert MapSet.member?(new_state.subscriptions, "ticker.BTC-PERPETUAL.raw")
      assert new_state.client.server_pid != initial_pid
    end

    test "adapter handles connection failures gracefully" do
      # Use invalid URL to force connection failure
      {:ok, adapter} =
        DeribitGenServerAdapter.start_link(
          url: "wss://invalid.example.com/ws",
          heartbeat_interval: 1
        )

      # Wait a bit
      Process.sleep(100)

      # Adapter should still be alive
      assert Process.alive?(adapter)

      # Should report not connected
      {:ok, state} = DeribitGenServerAdapter.get_state(adapter)
      assert state.client == nil

      # Operations should fail gracefully
      assert {:error, :not_connected} = DeribitGenServerAdapter.authenticate(adapter)
      assert {:error, :not_connected} = DeribitGenServerAdapter.subscribe(adapter, ["test"])
    end
  end

  describe "basic operations" do
    test "send_request handles various RPC methods" do
      {:ok, adapter} = DeribitGenServerAdapter.start_link(heartbeat_interval: 1)

      # Test public method - we expect an error because "get_instruments" is not a valid method name
      assert {:ok, %{"error" => %{"code" => -32_601, "message" => "Method not found"}}} =
               DeribitGenServerAdapter.send_request(adapter, "get_instruments", %{currency: "BTC"})

      # Test method that requires authentication (should work, but server will reject)
      assert {:ok, %{"error" => _}} =
               DeribitGenServerAdapter.send_request(adapter, "get_open_orders", %{currency: "BTC"})
    end
  end
end
