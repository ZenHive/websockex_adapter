defmodule WebsockexAdapter.Examples.DeribitAdapter do
  @moduledoc """
  Deribit WebSocket API adapter for WebsockexAdapter.

  Handles Deribit-specific functionality:
  - Authentication flow
  - Subscription management
  - Message format handling
  - Automatic heartbeat responses (handled by Client)
  """
  use WebsockexAdapter.JsonRpc

  alias WebsockexAdapter.Client
  alias WebsockexAdapter.JsonRpc
  alias WebsockexAdapter.MessageHandler

  require Logger

  defstruct [:client, :authenticated, :subscriptions, :client_id, :client_secret]

  @type t :: %__MODULE__{
          client: Client.t(),
          authenticated: boolean(),
          subscriptions: MapSet.t(),
          client_id: String.t() | nil,
          client_secret: String.t() | nil
        }

  @deribit_test_url "wss://test.deribit.com/ws/api/v2"

  # Define JSON-RPC methods using macro

  # Authentication & Session
  defrpc :auth_request, "public/auth", doc: "Authenticate with client credentials"
  defrpc :test_request, "public/test", doc: "Send test/heartbeat response"
  defrpc :set_heartbeat, "public/set_heartbeat", doc: "Set heartbeat interval"
  defrpc :disable_heartbeat, "public/disable_heartbeat", doc: "Disable heartbeat"

  # Subscriptions
  defrpc :subscribe_request, "public/subscribe", doc: "Subscribe to channels"
  defrpc :unsubscribe_request, "public/unsubscribe", doc: "Unsubscribe from channels"
  defrpc :unsubscribe_all, "public/unsubscribe_all", doc: "Unsubscribe from all channels"

  # Market Data
  defrpc :get_instruments, "public/get_instruments", doc: "Get tradable instruments"
  defrpc :get_order_book, "public/get_order_book", doc: "Get order book"
  defrpc :ticker, "public/ticker", doc: "Get ticker information"

  defrpc :get_book_summary_by_currency, "public/get_book_summary_by_currency", doc: "Get book summary by currency"

  defrpc :get_book_summary_by_instrument, "public/get_book_summary_by_instrument", doc: "Get book summary by instrument"

  defrpc :get_index_price, "public/get_index_price", doc: "Get index price"

  # Trading
  defrpc :buy, "private/buy", doc: "Place buy order"
  defrpc :sell, "private/sell", doc: "Place sell order"
  defrpc :cancel, "private/cancel", doc: "Cancel order"
  defrpc :cancel_all, "private/cancel_all", doc: "Cancel all orders"

  defrpc :cancel_all_by_instrument, "private/cancel_all_by_instrument", doc: "Cancel all orders by instrument"

  defrpc :edit, "private/edit", doc: "Edit order"
  defrpc :get_open_orders, "private/get_open_orders", doc: "Get open orders"

  defrpc :get_open_orders_by_currency, "private/get_open_orders_by_currency", doc: "Get open orders by currency"

  defrpc :get_open_orders_by_instrument, "private/get_open_orders_by_instrument", doc: "Get open orders by instrument"

  defrpc :get_order_state, "private/get_order_state", doc: "Get order state"

  # Account & Wallet
  defrpc :get_account_summary, "private/get_account_summary", doc: "Get account summary"
  defrpc :get_positions, "private/get_positions", doc: "Get positions"
  defrpc :get_position, "private/get_position", doc: "Get specific position"

  # Session Management
  defrpc :enable_cancel_on_disconnect, "private/enable_cancel_on_disconnect", doc: "Enable cancel on disconnect"

  defrpc :disable_cancel_on_disconnect, "private/disable_cancel_on_disconnect", doc: "Disable cancel on disconnect"

  @doc """
  Connect to Deribit WebSocket API with optional authentication.

  ## Options

  * `:client_id` - Client ID for authentication
  * `:client_secret` - Client secret for authentication
  * `:url` - WebSocket URL (defaults to test.deribit.com)
  * `:handler` - Message handler function
  * `:heartbeat_interval` - Heartbeat interval in seconds (default: 30)
  """
  @spec connect(keyword()) :: {:ok, t()} | {:error, term()}
  def connect(opts \\ []) do
    client_id = Keyword.get(opts, :client_id)
    client_secret = Keyword.get(opts, :client_secret)
    url = Keyword.get(opts, :url, @deribit_test_url)
    handler = Keyword.get(opts, :handler)
    heartbeat_interval = Keyword.get(opts, :heartbeat_interval, 30) * 1000

    connect_opts = [
      heartbeat_config: %{
        type: :deribit,
        interval: heartbeat_interval
      }
    ]

    connect_opts =
      if handler, do: Keyword.put(connect_opts, :handler, handler), else: connect_opts

    case Client.connect(url, connect_opts) do
      {:ok, client} ->
        adapter = %__MODULE__{
          client: client,
          authenticated: false,
          subscriptions: MapSet.new(),
          client_id: client_id,
          client_secret: client_secret
        }

        {:ok, adapter}

      error ->
        error
    end
  end

  @doc """
  Authenticate with Deribit using client credentials.
  """
  @spec authenticate(t()) :: {:ok, t()} | {:error, term()}
  def authenticate(%__MODULE__{client_id: nil}), do: {:error, :missing_credentials}

  def authenticate(%__MODULE__{client: client, client_id: client_id, client_secret: client_secret} = adapter) do
    {:ok, request} =
      auth_request(%{
        grant_type: "client_credentials",
        client_id: client_id,
        client_secret: client_secret
      })

    case Client.send_message(client, Jason.encode!(request)) do
      {:ok, %{"result" => %{"access_token" => _}}} ->
        # Set up heartbeat after authentication
        {:ok, heartbeat_request} = set_heartbeat(%{interval: 30})
        Client.send_message(client, Jason.encode!(heartbeat_request))

        {:ok, %{adapter | authenticated: true}}

      error ->
        error
    end
  end

  @doc """
  Subscribe to Deribit channels.
  """
  @spec subscribe(t(), list(String.t())) :: {:ok, t()} | {:error, term()}
  def subscribe(%__MODULE__{client: client, subscriptions: subs} = adapter, channels) when is_list(channels) do
    {:ok, request} = subscribe_request(%{channels: channels})

    case Client.send_message(client, Jason.encode!(request)) do
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
  def unsubscribe(%__MODULE__{client: client, subscriptions: subs} = adapter, channels) when is_list(channels) do
    {:ok, request} = unsubscribe_request(%{channels: channels})

    case Client.send_message(client, Jason.encode!(request)) do
      {:ok, %{"result" => _}} ->
        new_subs = Enum.reduce(channels, subs, &MapSet.delete(&2, &1))
        {:ok, %{adapter | subscriptions: new_subs}}

      error ->
        error
    end
  end

  @doc """
  Handle Deribit-specific messages (heartbeats handled automatically by Client).
  """
  @spec handle_message(term()) :: :ok
  def handle_message({:text, message}) do
    case Jason.decode(message) do
      {:ok, decoded} ->
        handle_decoded_message(decoded)

      {:error, _reason} ->
        :ok
    end
  end

  def handle_message(_message), do: :ok

  @doc """
  Create a message handler function for Deribit connections.
  """
  @spec create_message_handler(keyword()) :: function()
  def create_message_handler(opts \\ []) do
    on_message = Keyword.get(opts, :on_message, &default_message_handler/1)

    MessageHandler.create_handler(
      on_message: fn frame ->
        handle_message(frame)
        on_message.(frame)
      end,
      on_upgrade: fn upgrade_info ->
        Logger.debug("WebSocket connection upgraded: #{inspect(upgrade_info)}")
      end,
      on_error: fn error ->
        Logger.debug("WebSocket error: #{inspect(error)}")
      end
    )
  end

  # Private helper functions

  defp handle_decoded_message(%{"result" => %{"access_token" => _token}} = auth_result) do
    default_auth_handler(auth_result)
    :ok
  end

  defp handle_decoded_message(%{"error" => error} = error_response) do
    handle_error_message(error, error_response)
  end

  defp handle_decoded_message(%{"params" => %{"channel" => _channel, "data" => _data}} = notification) do
    default_message_handler(notification)
    :ok
  end

  defp handle_decoded_message(_message), do: :ok

  defp handle_error_message(%{"code" => code, "message" => message}, full_response) do
    error_data = {:error, {:api_error, code, message}}

    case WebsockexAdapter.ErrorHandler.handle_error(error_data) do
      :stop ->
        if auth_error?(code, message) do
          default_auth_error_handler({:auth_failed, code, message, full_response})
        else
          default_error_handler({:api_error, code, message, full_response})
        end

      _ ->
        default_error_handler({:api_error, code, message, full_response})
    end

    :ok
  end

  defp auth_error?(code, message) do
    case code do
      -32_600 -> String.contains?(message, "unauthorized")
      -32_602 -> String.contains?(message, "invalid_credentials")
      _ -> false
    end
  end

  defp default_message_handler(message) do
    Logger.debug("Deribit message: #{inspect(message)}")
  end

  defp default_auth_handler(auth_result) do
    Logger.debug("Authentication result: #{inspect(auth_result)}")
  end

  defp default_auth_error_handler(auth_error) do
    Logger.debug("Authentication error: #{inspect(auth_error)}")
  end

  defp default_error_handler(error) do
    Logger.debug("API error: #{inspect(error)}")
  end

  @doc """
  Send a generic request to Deribit API.
  """
  @spec send_request(t(), String.t(), map()) :: {:ok, term()} | {:error, term()}
  def send_request(%__MODULE__{client: client}, method, params \\ %{}) do
    {:ok, request} = JsonRpc.build_request(method, params)

    case Client.send_message(client, Jason.encode!(request)) do
      {:ok, response} -> {:ok, response}
      error -> error
    end
  end

  @doc """
  Close the WebSocket connection.
  """
  @spec close(t()) :: :ok
  def close(%__MODULE__{client: client}) do
    Client.close(client)
  end
end
