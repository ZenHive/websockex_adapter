defmodule WebsockexAdapter.Examples.BatchSubscriptionManager do
  @moduledoc """
  Simple batch subscription manager for efficiently subscribing to multiple channels.

  Prevents overwhelming the API by batching subscription requests with configurable
  batch size and delay between batches.
  """

  use GenServer

  alias WebsockexAdapter.Examples.DeribitAdapter

  @type batch_status :: %{
          completed: non_neg_integer(),
          pending: non_neg_integer(),
          total: non_neg_integer()
        }

  ## Public API (exactly 5 functions)

  @doc """
  Starts the batch subscription manager.

  ## Options
  - `:adapter` - The Deribit adapter process (required)
  - `:batch_size` - Number of channels per batch (default: 10)
  - `:batch_delay` - Delay between batches in ms (default: 200)

  ## Returns
  `{:ok, pid}` on success.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Subscribes to multiple channels in batches.

  ## Parameters
  - `manager` - The batch manager process
  - `channels` - List of channel names to subscribe to

  ## Returns
  `{:ok, request_id}` where request_id can be used to track progress.
  """
  @spec subscribe_batch(pid(), [String.t()]) :: {:ok, String.t()} | {:error, term()}
  def subscribe_batch(manager, channels) when is_list(channels) do
    GenServer.call(manager, {:subscribe_batch, channels})
  end

  @doc """
  Gets the status of a batch subscription request.

  ## Parameters
  - `manager` - The batch manager process
  - `request_id` - The request ID returned by subscribe_batch/2

  ## Returns
  - `{:ok, status}` with completed/pending/total counts
  - `{:error, :not_found}` if request_id is invalid
  """
  @spec get_status(pid(), String.t()) :: {:ok, batch_status()} | {:error, :not_found}
  def get_status(manager, request_id) do
    GenServer.call(manager, {:get_status, request_id})
  end

  @doc """
  Cancels a batch subscription request.

  ## Parameters
  - `manager` - The batch manager process
  - `request_id` - The request ID to cancel

  ## Returns
  - `:ok` if cancelled successfully
  - `{:error, :not_found}` if request_id is invalid
  """
  @spec cancel_batch(pid(), String.t()) :: :ok | {:error, :not_found}
  def cancel_batch(manager, request_id) do
    GenServer.call(manager, {:cancel_batch, request_id})
  end

  @doc """
  Gets the status of all batch requests.

  ## Returns
  `{:ok, statuses}` where statuses is a map of request_id => status.
  """
  @spec get_all_statuses(pid()) :: {:ok, map()}
  def get_all_statuses(manager) do
    GenServer.call(manager, :get_all_statuses)
  end

  ## GenServer Callbacks

  @impl true
  def init(opts) do
    state = %{
      adapter: Keyword.fetch!(opts, :adapter),
      batch_size: Keyword.get(opts, :batch_size, 10),
      batch_delay: Keyword.get(opts, :batch_delay, 200),
      requests: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:subscribe_batch, channels}, _from, state) do
    request_id = "req_#{[:positive] |> :erlang.unique_integer() |> Integer.to_string(16)}"
    total = length(channels)

    # Start processing immediately
    send(self(), {:process_batch, request_id, channels, 0})

    # Store request status
    state =
      put_in(state.requests[request_id], %{
        completed: 0,
        pending: total,
        total: total,
        cancelled: false
      })

    {:reply, {:ok, request_id}, state}
  end

  @impl true
  def handle_call({:get_status, request_id}, _from, state) do
    case state.requests[request_id] do
      nil -> {:reply, {:error, :not_found}, state}
      status -> {:reply, {:ok, Map.take(status, [:completed, :pending, :total])}, state}
    end
  end

  @impl true
  def handle_call({:cancel_batch, request_id}, _from, state) do
    case state.requests[request_id] do
      nil -> {:reply, {:error, :not_found}, state}
      _ -> {:reply, :ok, put_in(state.requests[request_id][:cancelled], true)}
    end
  end

  @impl true
  def handle_call(:get_all_statuses, _from, state) do
    statuses =
      Map.new(state.requests, fn {id, status} ->
        {id, Map.take(status, [:completed, :pending, :total])}
      end)

    {:reply, {:ok, statuses}, state}
  end

  @impl true
  def handle_info({:process_batch, request_id, channels, processed}, state) do
    if state.requests[request_id][:cancelled] or processed >= length(channels) do
      {:noreply, state}
    else
      # Take next batch
      batch = Enum.slice(channels, processed, state.batch_size)

      # Subscribe and update status regardless of success/failure
      DeribitAdapter.subscribe(state.adapter, batch)

      completed = min(processed + length(batch), length(channels))

      state =
        update_in(state.requests[request_id], fn status ->
          %{status | completed: completed, pending: status.total - completed}
        end)

      # Schedule next batch
      if completed < length(channels) do
        Process.send_after(self(), {:process_batch, request_id, channels, completed}, state.batch_delay)
      end

      {:noreply, state}
    end
  end
end
