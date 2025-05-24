defmodule WebsockexAdapter.Examples.DeribitHeartbeatTest do
  @moduledoc """
  Tests Deribit heartbeat functionality including:
  - Setting up heartbeats
  - Handling test_request messages automatically
  - Connection stability with heartbeats
  - Cancel-on-disconnect behavior
  """
  use ExUnit.Case, async: false

  alias WebsockexAdapter.Client
  alias WebsockexAdapter.Examples.DeribitAdapter

  require Logger

  @moduletag :integration
  @deribit_test_url "wss://test.deribit.com/ws/api/v2"

  describe "Deribit heartbeat" do
    test "enables heartbeat and connection remains stable" do
      # Connect to Deribit
      {:ok, adapter} = DeribitAdapter.connect()

      # Enable heartbeat with 10 second interval
      {:ok, heartbeat_request} = DeribitAdapter.set_heartbeat(%{interval: 10})
      assert {:ok, %{"id" => _, "result" => "ok"}} = Client.send_message(adapter.client, Jason.encode!(heartbeat_request))

      # Connection should remain stable for 25 seconds (2.5 heartbeat cycles)
      :timer.sleep(25_000)

      # Check connection is still alive
      state = Client.get_state(adapter.client)
      assert state == :connected

      # Send a test message to verify connection works
      {:ok, test_request} = DeribitAdapter.test_request()

      assert {:ok, %{"id" => _, "result" => %{"version" => _}}} =
               Client.send_message(adapter.client, Jason.encode!(test_request))

      # Disable heartbeat
      {:ok, disable_request} = DeribitAdapter.disable_heartbeat()
      assert {:ok, %{"id" => _, "result" => "ok"}} = Client.send_message(adapter.client, Jason.encode!(disable_request))

      # Clean up
      Client.close(adapter.client)
    end

    test "handles multiple heartbeat enable/disable cycles" do
      {:ok, adapter} = DeribitAdapter.connect()

      # Enable and disable heartbeat multiple times
      Enum.each(1..3, fn _i ->
        # Enable heartbeat
        {:ok, enable_request} = DeribitAdapter.set_heartbeat(%{interval: 10})
        assert {:ok, %{"id" => _, "result" => "ok"}} = Client.send_message(adapter.client, Jason.encode!(enable_request))

        :timer.sleep(5_000)

        # Disable heartbeat
        {:ok, disable_request} = DeribitAdapter.disable_heartbeat()
        assert {:ok, %{"id" => _, "result" => "ok"}} = Client.send_message(adapter.client, Jason.encode!(disable_request))

        # Verify connection still works
        assert Client.get_state(adapter.client) == :connected
      end)

      # Clean up
      Client.close(adapter.client)
    end
  end

  describe "Cancel-on-disconnect behavior" do
    @tag :skip_unless_env
    test "enables and disables cancel-on-disconnect" do
      client_id = System.get_env("DERIBIT_CLIENT_ID")
      client_secret = System.get_env("DERIBIT_CLIENT_SECRET")

      if client_id && client_secret do
        # Connect and authenticate
        {:ok, adapter} =
          DeribitAdapter.connect(
            client_id: client_id,
            client_secret: client_secret
          )

        :timer.sleep(1_000)
        {:ok, authenticated} = DeribitAdapter.authenticate(adapter)

        # Enable cancel-on-disconnect
        {:ok, enable_request} = DeribitAdapter.enable_cancel_on_disconnect()

        assert {:ok, %{"id" => _, "result" => "ok"}} =
                 Client.send_message(authenticated.client, Jason.encode!(enable_request))

        :timer.sleep(1_000)

        # Disable cancel-on-disconnect
        {:ok, disable_request} = DeribitAdapter.disable_cancel_on_disconnect()

        assert {:ok, %{"id" => _, "result" => "ok"}} =
                 Client.send_message(authenticated.client, Jason.encode!(disable_request))

        # Clean up
        Client.close(authenticated.client)
      else
        Logger.debug("Skipping cancel-on-disconnect test - no credentials provided")
      end
    end
  end

  describe "Integration with Client heartbeat config" do
    test "client maintains connection with Deribit heartbeat config" do
      # Connect with heartbeat configuration
      {:ok, config} = WebsockexAdapter.Config.new(@deribit_test_url)

      {:ok, client} =
        Client.connect(config,
          heartbeat_config: %{
            type: :deribit,
            interval: 10_000,
            test_request_handler: fn ->
              {:ok, request} = DeribitAdapter.test_request()
              Jason.encode!(request)
            end
          }
        )

      # Enable server-side heartbeat
      {:ok, heartbeat_request} = DeribitAdapter.set_heartbeat(%{interval: 10})
      assert {:ok, %{"id" => _, "result" => "ok"}} = Client.send_message(client, Jason.encode!(heartbeat_request))

      # Wait for multiple heartbeat cycles
      :timer.sleep(30_000)

      # Connection should still be active
      assert Client.get_state(client) == :connected

      # Disable heartbeat
      {:ok, disable_request} = DeribitAdapter.disable_heartbeat()
      assert {:ok, %{"id" => _, "result" => "ok"}} = Client.send_message(client, Jason.encode!(disable_request))

      # Clean up
      Client.close(client)
    end
  end
end
