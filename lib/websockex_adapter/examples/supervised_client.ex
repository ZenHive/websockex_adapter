defmodule WebsockexAdapter.Examples.SupervisedClient do
  @moduledoc """
  Example of using supervised WebSocket clients for production deployments.

  Supervised clients automatically restart on failure, providing resilience
  for financial trading systems.
  """
  alias WebsockexAdapter.Client
  alias WebsockexAdapter.ClientSupervisor
  alias WebsockexAdapter.Examples.DeribitAdapter

  require Logger

  @doc """
  Starts a supervised Deribit connection with automatic reconnection.

  ## Example

      # Start supervised connection
      {:ok, adapter} = SupervisedClient.start_deribit_connection(
        client_id: System.get_env("DERIBIT_CLIENT_ID"),
        client_secret: System.get_env("DERIBIT_CLIENT_SECRET")
      )

      # Use normally - will reconnect automatically on failures
      DeribitAdapter.subscribe(adapter, ["book.BTC-PERPETUAL.raw"])
  """
  def start_deribit_connection(opts \\ []) do
    # Configure Deribit connection
    config = [
      url: Keyword.get(opts, :url, "wss://test.deribit.com/ws/api/v2"),
      heartbeat_config: %{
        type: :deribit,
        interval: 30_000
      },
      retry_count: 10,
      retry_delay: 1000,
      max_backoff: 60_000
    ]

    # Start supervised client
    case ClientSupervisor.start_client(config[:url], config) do
      {:ok, client} ->
        # Create Deribit adapter with supervised client
        adapter = %DeribitAdapter{
          client: client,
          authenticated: false,
          subscriptions: MapSet.new(),
          client_id: Keyword.get(opts, :client_id),
          client_secret: Keyword.get(opts, :client_secret)
        }

        # Authenticate if credentials provided
        if adapter.client_id && adapter.client_secret do
          DeribitAdapter.authenticate(adapter)
        else
          {:ok, adapter}
        end

      error ->
        error
    end
  end

  @doc """
  Monitors client health and restarts if needed.

  ## Example

      # Start health monitoring
      SupervisedClient.monitor_health(client, interval: 60_000)
  """
  def monitor_health(client, opts \\ []) do
    interval = Keyword.get(opts, :interval, 60_000)

    Task.start(fn ->
      monitor_loop(client, interval)
    end)
  end

  defp monitor_loop(client, interval) do
    Process.sleep(interval)

    case Client.get_heartbeat_health(client) do
      %{failure_count: count} when count > 5 ->
        # Too many failures, restart the client
        Logger.debug("[HEALTH MONITOR] High failure count (#{count}), restarting client...")
        ClientSupervisor.stop_client(client.server_pid)

      %{last_heartbeat_at: nil} ->
        # No heartbeats received
        Logger.debug("[HEALTH MONITOR] No heartbeats received, checking connection...")

      %{last_heartbeat_at: last} ->
        # Check if heartbeat is stale
        age = System.system_time(:millisecond) - last
        # 2 minutes
        if age > 120_000 do
          Logger.debug("[HEALTH MONITOR] Stale heartbeat (#{age}ms old), restarting client...")
          ClientSupervisor.stop_client(client.server_pid)
        end

      _ ->
        # Client not responding
        Logger.debug("[HEALTH MONITOR] Client not responding")
    end

    # Continue monitoring
    monitor_loop(client, interval)
  end

  @doc """
  Lists all active supervised connections.
  """
  def list_connections do
    Enum.map(ClientSupervisor.list_clients(), fn pid ->
      # Get client state for each pid
      state = GenServer.call(pid, :get_state)

      %{
        pid: pid,
        state: state,
        alive: Process.alive?(pid)
      }
    end)
  end
end
