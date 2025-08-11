defmodule ZenWebsocket.Examples.SupervisedClient do
  @moduledoc """
  Basic WebSocket client supervision example.

  Shows minimal setup for supervised connections. For advanced patterns,
  see the supervision documentation.
  """
  alias ZenWebsocket.ClientSupervisor

  @doc """
  Starts a supervised WebSocket connection.

  ## Example

      {:ok, client} = SupervisedClient.start_connection("wss://echo.websocket.org")
  """
  def start_connection(url, opts \\ []) do
    ClientSupervisor.start_client(url, opts)
  end

  @doc """
  Starts multiple supervised connections.

  ## Example

      clients = SupervisedClient.start_multiple([
        {"wss://api1.example.com", retry_count: 5},
        {"wss://api2.example.com", heartbeat_interval: 20_000}
      ])
  """
  def start_multiple(configs) do
    Enum.map(configs, fn {url, opts} ->
      case ClientSupervisor.start_client(url, opts) do
        {:ok, client} -> {url, {:ok, client}}
        error -> {url, error}
      end
    end)
  end

  @doc """
  Lists all supervised connections.
  """
  def list_connections do
    ClientSupervisor.list_clients()
  end

  @doc """
  Stops a supervised connection.
  """
  def stop_connection(client_pid) do
    ClientSupervisor.stop_client(client_pid)
  end
end
