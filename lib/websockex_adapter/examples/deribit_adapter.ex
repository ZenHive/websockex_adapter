defmodule WebsockexAdapter.Examples.DeribitAdapter do
  @moduledoc """
  Simplified Deribit WebSocket API adapter.

  Uses DeribitRpc for all RPC operations and provides
  5 essential functions for Deribit integration.
  """

  alias WebsockexAdapter.Client
  alias WebsockexAdapter.Examples.DeribitRpc

  require Logger

  defstruct [:client, :authenticated, :subscriptions, :client_id, :client_secret]

  @type t :: %__MODULE__{
          client: Client.t() | nil,
          authenticated: boolean(),
          subscriptions: MapSet.t(),
          client_id: String.t() | nil,
          client_secret: String.t() | nil
        }

  @deribit_test_url "wss://test.deribit.com/ws/api/v2"

  @doc """
  Connect to Deribit WebSocket API.

  Options:
  - `:client_id` - Client ID for authentication
  - `:client_secret` - Client secret for authentication
  - `:url` - WebSocket URL (defaults to test.deribit.com)
  - `:handler` - Message handler function
  - `:heartbeat_interval` - Heartbeat interval in seconds (default: 30)
  """
  @spec connect(keyword()) :: {:ok, t()} | {:error, term()}
  def connect(opts \\ []) do
    url = Keyword.get(opts, :url, @deribit_test_url)
    heartbeat_interval = Keyword.get(opts, :heartbeat_interval, 30) * 1000

    connect_opts = [
      heartbeat_config: %{
        type: :deribit,
        interval: heartbeat_interval
      }
    ]

    connect_opts =
      if handler = opts[:handler],
        do: Keyword.put(connect_opts, :handler, handler),
        else: connect_opts

    case Client.connect(url, connect_opts) do
      {:ok, client} ->
        {:ok,
         %__MODULE__{
           client: client,
           authenticated: false,
           subscriptions: MapSet.new(),
           client_id: opts[:client_id],
           client_secret: opts[:client_secret]
         }}

      error ->
        error
    end
  end

  @doc """
  Authenticate with Deribit using client credentials.
  """
  @spec authenticate(t()) :: {:ok, t()} | {:error, term()}
  def authenticate(%__MODULE__{client_id: nil}), do: {:error, :missing_credentials}

  def authenticate(%__MODULE__{client: client} = adapter) do
    request = DeribitRpc.auth_request(adapter.client_id, adapter.client_secret)

    case send_json_rpc(client, request) do
      {:ok, %{"result" => %{"access_token" => _}}} ->
        # Set up heartbeat after authentication
        send_json_rpc(client, DeribitRpc.set_heartbeat(30))
        {:ok, %{adapter | authenticated: true}}

      error ->
        error
    end
  end

  @doc """
  Subscribe to Deribit channels.
  """
  @spec subscribe(t(), list(String.t())) :: {:ok, t()} | {:error, term()}
  def subscribe(%__MODULE__{client: client, subscriptions: subs} = adapter, channels) do
    case send_json_rpc(client, DeribitRpc.subscribe(channels)) do
      {:ok, %{"result" => _}} ->
        new_subs = Enum.reduce(channels, subs, &MapSet.put(&2, &1))
        {:ok, %{adapter | subscriptions: new_subs}}

      error ->
        error
    end
  end

  @doc """
  Unsubscribe from Deribit channels.
  """
  @spec unsubscribe(t(), list(String.t())) :: {:ok, t()} | {:error, term()}
  def unsubscribe(%__MODULE__{client: client, subscriptions: subs} = adapter, channels) do
    case send_json_rpc(client, DeribitRpc.unsubscribe(channels)) do
      {:ok, %{"result" => _}} ->
        new_subs = Enum.reduce(channels, subs, &MapSet.delete(&2, &1))
        {:ok, %{adapter | subscriptions: new_subs}}

      error ->
        error
    end
  end

  @doc """
  Send a request to Deribit API using any supported method.
  """
  @spec send_request(t(), String.t(), map()) :: {:ok, term()} | {:error, term()}
  def send_request(%__MODULE__{client: client}, method, params \\ %{}) do
    request = DeribitRpc.build_request(method, params)
    send_json_rpc(client, request)
  end

  # Private helper to send JSON-RPC requests
  defp send_json_rpc(client, request) do
    case Client.send_message(client, Jason.encode!(request)) do
      {:ok, response} -> {:ok, response}
      error -> error
    end
  end
end
