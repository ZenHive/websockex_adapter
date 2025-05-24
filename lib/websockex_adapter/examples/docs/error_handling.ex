defmodule WebsockexAdapter.Examples.Docs.ErrorHandling do
  @moduledoc """
  Error handling and retry patterns from Examples.md
  """

  use GenServer

  alias WebsockexAdapter.Client

  require Logger

  def start_link(url, opts \\ []) do
    GenServer.start_link(__MODULE__, {url, opts}, name: __MODULE__)
  end

  def init({url, opts}) do
    case Client.connect(url, opts) do
      {:ok, client} ->
        {:ok, %{client: client, url: url, opts: opts, retry_count: 0}}

      {:error, reason} ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        # Retry after delay
        Process.send_after(self(), :retry_connect, 5_000)
        {:ok, %{client: nil, url: url, opts: opts, retry_count: 1}}
    end
  end

  def handle_info(:retry_connect, %{url: url, opts: opts, retry_count: count} = state) do
    case Client.connect(url, opts) do
      {:ok, client} ->
        Logger.info("Reconnected successfully after #{count} attempts")
        {:noreply, %{state | client: client, retry_count: 0}}

      {:error, _reason} ->
        Process.send_after(self(), :retry_connect, 5_000)
        {:noreply, %{state | retry_count: count + 1}}
    end
  end

  def handle_info({:websocket_message, message}, state) do
    # Process incoming messages
    process_message(message)
    {:noreply, state}
  end

  def handle_info({:websocket_error, error}, state) do
    Logger.error("WebSocket error: #{inspect(error)}")
    {:noreply, state}
  end

  # Public API
  def send_message(message) do
    GenServer.call(__MODULE__, {:send_message, message})
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def handle_call({:send_message, _message}, _from, %{client: nil} = state) do
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:send_message, message}, _from, %{client: client} = state) do
    result = Client.send_message(client, message)
    {:reply, result, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # Helper functions
  defp process_message(message) do
    Logger.debug("Processing message: #{inspect(message)}")
    # Application-specific message processing
    :ok
  end
end
