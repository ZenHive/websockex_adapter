defmodule ZenWebsocket.Reconnection do
  @moduledoc """
  Internal reconnection helper for Client GenServer.

  This module provides reconnection logic that runs within the Client GenServer
  process to maintain Gun message ownership. It handles:

  - Connection establishment with retry logic
  - Exponential backoff calculations
  - Subscription restoration after reconnection

  ## Architecture

  This module is called by the Client GenServer during its handle_continue
  and handle_info callbacks. All functions run in the Client GenServer process
  to ensure the new Gun connection sends messages to the correct process.

  ## Not for External Use

  This module is internal to ZenWebsocket. External code should use
  `ZenWebsocket.Client.connect/2` which handles initial connection attempts
  and automatic reconnection.
  """
  alias ZenWebsocket.Config

  require Logger

  @doc """
  Attempt to establish a Gun connection with the given configuration.

  This function must be called from within the Client GenServer process
  to ensure Gun sends messages to the correct process.
  """
  @spec establish_connection(Config.t()) ::
          {:ok, gun_pid :: pid(), stream_ref :: reference(), monitor_ref :: reference()}
          | {:error, term()}
  def establish_connection(%Config{} = config) do
    uri = URI.parse(config.url)
    port = uri.port || if uri.scheme == "wss", do: 443, else: 80

    Logger.debug("🔫 [GUN OPEN] #{DateTime.to_string(DateTime.utc_now())}")
    Logger.debug("   🌐 Host: #{uri.host}")
    Logger.debug("   🔌 Port: #{port}")
    Logger.debug("   📋 Scheme: #{uri.scheme}")
    Logger.debug("   📍 Path: #{uri.path || "/"}")
    Logger.debug("   🔄 Opening Gun connection...")

    # Gun sends messages to the calling process (Client GenServer)
    case :gun.open(to_charlist(uri.host), port, %{protocols: [:http]}) do
      {:ok, gun_pid} ->
        Logger.debug("   ✅ Gun connection opened successfully")
        Logger.debug("   🔧 Gun PID: #{inspect(gun_pid)}")
        Logger.debug("   👁️  Setting up process monitor...")

        monitor_ref = Process.monitor(gun_pid)
        Logger.debug("   📍 Monitor Ref: #{inspect(monitor_ref)}")
        Logger.debug("   ⏳ Awaiting Gun up (timeout: #{config.timeout}ms)...")

        case :gun.await_up(gun_pid, config.timeout) do
          {:ok, protocol} ->
            Logger.debug("   ✅ Gun connection up")
            Logger.debug("   🌐 Protocol: #{inspect(protocol)}")
            Logger.debug("   🔄 Upgrading to WebSocket...")
            Logger.debug("   📋 Headers: #{inspect(config.headers)}")

            stream_ref = :gun.ws_upgrade(gun_pid, uri.path || "/", config.headers)
            Logger.debug("   📡 WebSocket upgrade initiated")
            Logger.debug("   📡 Stream Ref: #{inspect(stream_ref)}")
            Logger.debug("   ✅ Connection establishment complete")

            {:ok, gun_pid, stream_ref, monitor_ref}

          {:error, reason} ->
            Logger.debug("   ❌ Gun await_up failed: #{inspect(reason)}")
            Logger.debug("   🧹 Cleaning up monitor and closing Gun...")

            Process.demonitor(monitor_ref, [:flush])
            :gun.close(gun_pid)
            {:error, reason}
        end

      {:error, reason} ->
        Logger.debug("   ❌ Gun open failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Calculate exponential backoff delay for reconnection attempts.

  ## Examples

      iex> calculate_backoff(0, 1000)
      1000

      iex> calculate_backoff(1, 1000)
      2000

      iex> calculate_backoff(5, 1000, 30000)
      30000  # Capped at max_backoff
  """
  @spec calculate_backoff(
          attempt :: non_neg_integer(),
          base_delay :: pos_integer(),
          max_backoff :: pos_integer() | nil
        ) ::
          pos_integer()
  def calculate_backoff(attempt, base_delay, max_backoff \\ 30_000) do
    delay = base_delay * :math.pow(2, attempt)
    max_delay = max_backoff || 30_000
    min(round(delay), max_delay)
  end

  @doc """
  Determine if a connection error should trigger reconnection.

  Returns true for recoverable errors like network issues, false for
  unrecoverable errors like invalid credentials.
  """
  @spec should_reconnect?(error :: term()) :: boolean()
  def should_reconnect?(error) do
    case ZenWebsocket.ErrorHandler.handle_error(error) do
      :reconnect -> true
      _ -> false
    end
  end

  @doc """
  Check if maximum retry attempts have been exceeded.
  """
  @spec max_retries_exceeded?(attempt :: non_neg_integer(), max_retries :: non_neg_integer()) ::
          boolean()
  def max_retries_exceeded?(attempt, max_retries) do
    attempt >= max_retries
  end

  @doc """
  Restore subscriptions after successful reconnection.

  This should be called after the WebSocket upgrade is complete and the
  connection is ready to receive subscription messages.
  """
  @spec restore_subscriptions(
          gun_pid :: pid(),
          stream_ref :: reference(),
          subscriptions :: [String.t()]
        ) :: :ok
  def restore_subscriptions(_gun_pid, _stream_ref, []), do: :ok

  def restore_subscriptions(gun_pid, stream_ref, subscriptions) when is_list(subscriptions) do
    Logger.debug("📡 [RESTORE SUBSCRIPTIONS] #{DateTime.to_string(DateTime.utc_now())}")
    Logger.debug("   🔧 Gun PID: #{inspect(gun_pid)}")
    Logger.debug("   📡 Stream Ref: #{inspect(stream_ref)}")
    Logger.debug("   📋 Subscriptions: #{inspect(subscriptions)}")

    message =
      Jason.encode!(%{
        "jsonrpc" => "2.0",
        "method" => "public/subscribe",
        "params" => %{"channels" => subscriptions},
        "id" => System.unique_integer([:positive])
      })

    Logger.debug("   📤 Sending subscription restore message...")
    :gun.ws_send(gun_pid, stream_ref, {:text, message})
    Logger.debug("   ✅ Subscription restoration complete")
    :ok
  end
end
