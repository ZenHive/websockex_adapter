defmodule WebsockexAdapter.Examples.DeribitGenServerAdapter do
  @moduledoc """
  GenServer-based Deribit WebSocket API adapter with fault tolerance.

  Monitors the Client GenServer and handles automatic reconnection
  with state restoration when the client process dies.

  The architecture now provides true fault tolerance where:
  - Client GenServers can crash and be restarted by ClientSupervisor
  - Adapter GenServers monitor their clients and handle reconnection seamlessly
  - Users of the adapter don't need to worry about Client process deaths
  - Both authentication and subscriptions are automatically restored
  """

  use GenServer
  use WebsockexAdapter.JsonRpc

  alias WebsockexAdapter.Client

  require Logger

  @type state :: %{
          client: Client.t() | nil,
          monitor_ref: reference() | nil,
          authenticated: boolean(),
          was_authenticated: boolean(),
          subscriptions: MapSet.t(),
          client_id: String.t() | nil,
          client_secret: String.t() | nil,
          url: String.t(),
          opts: keyword()
        }

  @deribit_test_url "wss://test.deribit.com/ws/api/v2"
  @reconnect_delay 5_000

  # Define JSON-RPC methods using macro
  defrpc :auth_request, "public/auth", doc: "Authenticate with client credentials"
  defrpc :test_request, "public/test", doc: "Send test/heartbeat response"
  defrpc :set_heartbeat, "public/set_heartbeat", doc: "Set heartbeat interval"
  defrpc :subscribe_request, "public/subscribe", doc: "Subscribe to channels"
  defrpc :unsubscribe_request, "public/unsubscribe", doc: "Unsubscribe from channels"

  # Market Data
  defrpc :get_instruments, "public/get_instruments", doc: "Get tradable instruments"
  defrpc :get_order_book, "public/get_order_book", doc: "Get order book"
  defrpc :ticker, "public/ticker", doc: "Get ticker information"

  # Trading
  defrpc :buy, "private/buy", doc: "Place buy order"
  defrpc :sell, "private/sell", doc: "Place sell order"
  defrpc :cancel, "private/cancel", doc: "Cancel order"
  defrpc :get_open_orders, "private/get_open_orders", doc: "Get open orders"

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def authenticate(adapter) do
    GenServer.call(adapter, :authenticate)
  end

  def subscribe(adapter, channels) do
    GenServer.call(adapter, {:subscribe, channels})
  end

  def unsubscribe(adapter, channels) do
    GenServer.call(adapter, {:unsubscribe, channels})
  end

  def send_request(adapter, method, params \\ %{}) do
    GenServer.call(adapter, {:send_request, method, params})
  end

  def get_state(adapter) do
    GenServer.call(adapter, :get_state)
  end

  # Server callbacks

  @impl true
  def init(opts) do
    state = %{
      client: nil,
      monitor_ref: nil,
      authenticated: false,
      was_authenticated: false,
      subscriptions: MapSet.new(),
      client_id: Keyword.get(opts, :client_id),
      client_secret: Keyword.get(opts, :client_secret),
      url: Keyword.get(opts, :url, @deribit_test_url),
      opts: opts
    }

    # Attempt initial connection
    send(self(), :connect)

    {:ok, state}
  end

  @impl true
  def handle_call(:authenticate, _from, %{client: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call(:authenticate, _from, %{client_id: nil} = state) do
    {:reply, {:error, :missing_credentials}, state}
  end

  def handle_call(:authenticate, _from, state) do
    case do_authenticate(state) do
      {:ok, new_state} ->
        {:reply, :ok, %{new_state | was_authenticated: true}}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:subscribe, _channels}, _from, %{client: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:subscribe, channels}, _from, state) do
    case do_subscribe(state, channels) do
      {:ok, new_state} ->
        {:reply, :ok, new_state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:unsubscribe, _channels}, _from, %{client: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:unsubscribe, channels}, _from, state) do
    case do_unsubscribe(state, channels) do
      {:ok, new_state} ->
        {:reply, :ok, new_state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:send_request, _method, _params}, _from, %{client: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:send_request, method, params}, _from, %{client: client} = state) do
    # Build the JSON-RPC request directly
    request = %{
      jsonrpc: "2.0",
      id: System.unique_integer([:positive]),
      method: method,
      params: params
    }

    result = Client.send_message(client, Jason.encode!(request))
    {:reply, result, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_info(:connect, state) do
    case do_connect(state) do
      {:ok, new_state} ->
        {:noreply, new_state}

      {:error, reason} ->
        Logger.warning("Failed to connect: #{inspect(reason)}, retrying in #{@reconnect_delay}ms")
        Process.send_after(self(), :connect, @reconnect_delay)
        {:noreply, state}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %{monitor_ref: ref} = state) do
    Logger.warning("Client process died: #{inspect(reason)}, reconnecting...")

    # Keep track that we were authenticated before the crash
    was_auth = state.authenticated || state.was_authenticated

    new_state = %{
      state
      | client: nil,
        monitor_ref: nil,
        authenticated: false,
        was_authenticated: was_auth
    }

    send(self(), :connect)

    {:noreply, new_state}
  end

  def handle_info(:restore_state, %{authenticated: false, was_authenticated: true} = state) do
    # Re-authenticate since we were authenticated before
    case do_authenticate(state) do
      {:ok, auth_state} ->
        # Then restore subscriptions
        case restore_subscriptions(auth_state) do
          {:ok, final_state} ->
            {:noreply, final_state}

          {:error, _reason} ->
            # Try again later
            Process.send_after(self(), :restore_state, @reconnect_delay)
            {:noreply, auth_state}
        end

      {:error, _reason} ->
        # Try again later
        Process.send_after(self(), :restore_state, @reconnect_delay)
        {:noreply, state}
    end
  end

  def handle_info(:restore_state, %{subscriptions: subs} = state) when map_size(subs) > 0 do
    # Already authenticated, just restore subscriptions
    case restore_subscriptions(state) do
      {:ok, new_state} ->
        {:noreply, new_state}

      {:error, _reason} ->
        Process.send_after(self(), :restore_state, @reconnect_delay)
        {:noreply, state}
    end
  end

  def handle_info(:restore_state, state) do
    # Nothing to restore
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    # Ignore other messages
    {:noreply, state}
  end

  # Private functions

  defp do_connect(state) do
    heartbeat_interval = Keyword.get(state.opts, :heartbeat_interval, 30) * 1000
    handler = Keyword.get(state.opts, :handler)

    connect_opts = [
      heartbeat_config: %{
        type: :deribit,
        interval: heartbeat_interval
      },
      reconnect_on_error: false
    ]

    connect_opts =
      if handler, do: Keyword.put(connect_opts, :handler, handler), else: connect_opts

    case Client.connect(state.url, connect_opts) do
      {:ok, client} ->
        ref = Process.monitor(client.server_pid)
        new_state = %{state | client: client, monitor_ref: ref}

        # Restore state if needed
        if state.was_authenticated or MapSet.size(state.subscriptions) > 0 do
          send(self(), :restore_state)
        end

        {:ok, new_state}

      error ->
        error
    end
  end

  defp do_authenticate(state) do
    {:ok, request} =
      auth_request(%{
        grant_type: "client_credentials",
        client_id: state.client_id,
        client_secret: state.client_secret
      })

    case Client.send_message(state.client, Jason.encode!(request)) do
      {:ok, %{"result" => %{"access_token" => _}}} ->
        # Set up heartbeat after authentication
        {:ok, heartbeat_request} = set_heartbeat(%{interval: 30})
        Client.send_message(state.client, Jason.encode!(heartbeat_request))

        {:ok, %{state | authenticated: true}}

      error ->
        error
    end
  end

  defp do_subscribe(state, channels) do
    {:ok, request} = subscribe_request(%{channels: channels})

    case Client.send_message(state.client, Jason.encode!(request)) do
      {:ok, %{"result" => _}} ->
        new_subs = Enum.reduce(channels, state.subscriptions, &MapSet.put(&2, &1))
        {:ok, %{state | subscriptions: new_subs}}

      error ->
        error
    end
  end

  defp do_unsubscribe(state, channels) do
    {:ok, request} = unsubscribe_request(%{channels: channels})

    case Client.send_message(state.client, Jason.encode!(request)) do
      {:ok, %{"result" => _}} ->
        new_subs = Enum.reduce(channels, state.subscriptions, &MapSet.delete(&2, &1))
        {:ok, %{state | subscriptions: new_subs}}

      error ->
        error
    end
  end

  defp restore_subscriptions(%{subscriptions: subs} = state) when map_size(subs) == 0 do
    {:ok, state}
  end

  defp restore_subscriptions(%{subscriptions: subs} = state) do
    channels = MapSet.to_list(subs)
    Logger.info("Restoring #{length(channels)} subscriptions")

    do_subscribe(%{state | subscriptions: MapSet.new()}, channels)
  end
end
