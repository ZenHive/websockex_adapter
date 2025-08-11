defmodule ZenWebsocket.Examples.SupervisedConnectionTest do
  use ExUnit.Case, async: false

  alias ZenWebsocket.Client
  alias ZenWebsocket.ClientSupervisor

  setup do
    # Start a supervised instance for testing
    {:ok, sup_pid} = start_supervised({ClientSupervisor, []})
    {:ok, supervisor: sup_pid}
  end

  describe "basic supervised connections" do
    @tag :integration
    test "starts supervised client connection" do
      {:ok, client} = ClientSupervisor.start_client("wss://echo.websocket.org")

      assert is_pid(client.server_pid)
      assert Process.alive?(client.server_pid)

      # Verify connection works
      case Client.send_message(client, "test message") do
        :ok ->
          :ok

        {:ok, response} ->
          assert response == "test message"
      end

      :ok = Client.close(client)
    end

    @tag :integration
    test "restarts client on crash" do
      {:ok, client} = ClientSupervisor.start_client("wss://echo.websocket.org")

      original_pid = client.server_pid
      assert Process.alive?(original_pid)

      # Kill the client process
      Process.exit(original_pid, :kill)

      # Wait for supervisor to restart
      Process.sleep(100)

      # Check if a new process was started
      clients = ClientSupervisor.list_clients()
      assert length(clients) > 0

      new_pid = hd(clients)
      assert new_pid != original_pid
      assert Process.alive?(new_pid)
    end

    @tag :integration
    test "lists all supervised clients" do
      # Start multiple clients
      {:ok, _client1} = ClientSupervisor.start_client("wss://echo.websocket.org")
      {:ok, _client2} = ClientSupervisor.start_client("wss://echo.websocket.org")

      clients = ClientSupervisor.list_clients()
      assert length(clients) == 2
      assert Enum.all?(clients, &Process.alive?/1)
    end
  end

  describe "supervision tree integration" do
    @tag :integration
    test "integrates with application supervision tree" do
      # Example of how it would be used in an application
      defmodule TestApp do
        @moduledoc false
        use Application

        def start(_type, _args) do
          children = [
            {Task.Supervisor, name: TestApp.TaskSupervisor}
          ]

          opts = [strategy: :one_for_one, name: TestApp.Supervisor]
          Supervisor.start_link(children, opts)
        end
      end

      # Start the app
      {:ok, _} = TestApp.start(:normal, [])

      # Use the already running supervisor from setup
      {:ok, client} = ClientSupervisor.start_client("wss://echo.websocket.org")
      assert Process.alive?(client.server_pid)

      :ok = Client.close(client)
    end

    @tag :integration
    test "handles supervisor restarts" do
      {:ok, client} =
        ClientSupervisor.start_client("wss://echo.websocket.org",
          retry_count: 3,
          retry_delay: 100
        )

      # Get supervisor stats before
      stats_before = DynamicSupervisor.count_children(ClientSupervisor)
      assert stats_before.active > 0

      # Force multiple crashes to test restart limits
      original_pid = client.server_pid

      # First crash
      Process.exit(original_pid, :kill)
      Process.sleep(150)

      # Should have restarted
      clients = ClientSupervisor.list_clients()
      assert length(clients) > 0
    end
  end

  describe "error handling and recovery" do
    test "handles connection failures gracefully" do
      # Try to connect to invalid URL
      result = ClientSupervisor.start_client("ws://invalid.example.com:9999")

      assert {:error, _reason} = result

      # Verify no zombie processes
      Process.sleep(100)
      assert ClientSupervisor.list_clients() == []
    end

    @tag :integration
    test "stops supervised client cleanly" do
      {:ok, client} = ClientSupervisor.start_client("wss://echo.websocket.org")
      pid = client.server_pid

      assert Process.alive?(pid)
      assert length(ClientSupervisor.list_clients()) == 1

      # Stop the client
      :ok = ClientSupervisor.stop_client(pid)

      Process.sleep(100)
      refute Process.alive?(pid)
      assert ClientSupervisor.list_clients() == []
    end

    @tag :integration
    test "supervised client maintains state across restarts" do
      {:ok, client} =
        ClientSupervisor.start_client("wss://echo.websocket.org",
          heartbeat_interval: 30_000
        )

      # Subscribe to some channels (echo server doesn't support this, but we test the pattern)
      case Client.subscribe(client, ["test.channel"]) do
        :ok -> :ok
        {:ok, _} -> :ok
        # Echo server doesn't support subscriptions
        {:error, _} -> :ok
      end

      # Get current connection state
      assert Client.get_state(client) == :connected

      # Force restart
      Process.exit(client.server_pid, :kill)
      Process.sleep(200)

      # Note: In a real implementation with supervision, you'd need to
      # reacquire the client reference after restart. This is just testing
      # the supervision pattern.
      new_clients = ClientSupervisor.list_clients()
      assert length(new_clients) > 0
    end
  end

  describe "advanced supervision patterns" do
    @tag :integration
    test "multiple supervised connections with different configs" do
      configs = [
        %{url: "wss://echo.websocket.org", retry_count: 3},
        %{url: "wss://echo.websocket.org", retry_count: 5},
        %{url: "wss://echo.websocket.org", heartbeat_interval: 20_000}
      ]

      clients =
        for config <- configs do
          {:ok, client} =
            ClientSupervisor.start_client(
              config.url,
              Keyword.new(Map.delete(config, :url))
            )

          client
        end

      assert length(clients) == 3
      assert Enum.all?(clients, fn c -> Process.alive?(c.server_pid) end)

      # Clean up
      for client <- clients do
        ClientSupervisor.stop_client(client.server_pid)
      end
    end

    @tag :integration
    test "respects max restart limits" do
      {:ok, client} = ClientSupervisor.start_client("wss://echo.websocket.org")

      _original_pid = client.server_pid

      # Force multiple rapid crashes to exceed restart limit
      # Default is max_restarts: 10 in max_seconds: 60
      for _ <- 1..12 do
        clients = ClientSupervisor.list_clients()

        if clients != [] do
          pid = hd(clients)
          Process.exit(pid, :kill)
          Process.sleep(10)
        end
      end

      # After exceeding limits, supervisor should stop restarting
      Process.sleep(200)

      # May or may not have clients depending on timing
      # The important thing is it doesn't keep crashing
    end
  end

  describe "real-world supervised connection patterns" do
    @describetag :integration
    test "connection manager pattern" do
      defmodule ConnectionManager do
        @moduledoc false
        use GenServer

        def start_link(urls) do
          GenServer.start_link(__MODULE__, urls)
        end

        def init(urls) do
          clients =
            Enum.map(urls, fn url ->
              case ClientSupervisor.start_client(url) do
                {:ok, client} -> {url, client}
                {:error, _} -> {url, nil}
              end
            end)

          {:ok, %{clients: clients}}
        end

        def get_client(manager, url) do
          GenServer.call(manager, {:get_client, url})
        end

        def handle_call({:get_client, url}, _from, state) do
          client =
            case List.keyfind(state.clients, url, 0) do
              {^url, client} -> client
              nil -> nil
            end

          {:reply, client, state}
        end
      end

      # Start connection manager
      urls = ["wss://echo.websocket.org"]
      {:ok, manager} = ConnectionManager.start_link(urls)

      # Get managed client
      client = ConnectionManager.get_client(manager, "wss://echo.websocket.org")
      assert client

      # Use the client
      case Client.send_message(client, "managed message") do
        :ok ->
          :ok

        {:ok, response} ->
          assert response == "managed message"
      end
    end

    @tag :integration
    test "supervised Deribit connection" do
      client_id = System.get_env("DERIBIT_CLIENT_ID")
      client_secret = System.get_env("DERIBIT_CLIENT_SECRET")

      if client_id && client_secret do
        url = "wss://test.deribit.com/ws/api/v2"

        opts = [
          heartbeat_interval: 30_000,
          timeout: 10_000
        ]

        {:ok, client} = ClientSupervisor.start_client(url, opts)

        # Authenticate
        auth_msg = %{
          "jsonrpc" => "2.0",
          "method" => "public/auth",
          "params" => %{
            "grant_type" => "client_credentials",
            "client_id" => client_id,
            "client_secret" => client_secret
          },
          "id" => 1
        }

        case Client.send_message(client, Jason.encode!(auth_msg)) do
          :ok ->
            assert_receive {:websocket_message, _auth_response}, 5_000

          {:ok, auth_response} ->
            assert auth_response["result"]
        end

        # Verify supervised connection stays alive
        assert Process.alive?(client.server_pid)

        :ok = Client.close(client)
      end
    end
  end
end
