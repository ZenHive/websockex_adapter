defmodule WebsockexAdapter.Examples.BatchSubscriptionManager do
  @moduledoc """
  Batch subscription manager for efficiently subscribing to multiple channels.

  Prevents overwhelming the API by batching subscription requests with configurable
  batch size and delay between batches. Essential for subscribing to large numbers
  of channels (e.g., orderbook data for 50+ instruments).

  ## Example

      {:ok, manager} = BatchSubscriptionManager.start_link(
        adapter: deribit_adapter,
        batch_size: 10,
        batch_delay: 200
      )

      channels = for i <- 1..50, do: "book.BTC-\#{i}JUN25.raw"
      {:ok, request_id} = BatchSubscriptionManager.subscribe_batch(manager, channels)

      {:ok, status} = BatchSubscriptionManager.get_status(manager, request_id)
  """

  use GenServer

  alias WebsockexAdapter.Examples.DeribitAdapter

  require Logger

  @type request_id :: String.t()
  @type channel :: String.t()
  @type batch_status :: %{
          completed: non_neg_integer(),
          pending: non_neg_integer(),
          failed: non_neg_integer(),
          total: non_neg_integer()
        }

  ## Public API

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec subscribe_batch(pid(), [channel()]) :: {:ok, request_id()} | {:error, term()}
  def subscribe_batch(manager, channels) when is_list(channels) do
    GenServer.call(manager, {:subscribe_batch, channels})
  end

  @spec get_status(pid(), request_id()) :: {:ok, batch_status()} | {:error, :not_found}
  def get_status(manager, request_id) do
    GenServer.call(manager, {:get_status, request_id})
  end

  @spec cancel_batch(pid(), request_id()) :: :ok | {:error, :not_found}
  def cancel_batch(manager, request_id) do
    GenServer.call(manager, {:cancel_batch, request_id})
  end

  @spec get_all_statuses(pid()) :: {:ok, map()}
  def get_all_statuses(manager) do
    GenServer.call(manager, :get_all_statuses)
  end

  ## GenServer Callbacks

  @impl true
  def init(opts) do
    adapter = Keyword.fetch!(opts, :adapter)
    batch_size = Keyword.get(opts, :batch_size, 10)
    batch_delay = Keyword.get(opts, :batch_delay, 200)

    state = %{
      adapter: adapter,
      batch_size: batch_size,
      batch_delay: batch_delay,
      requests: %{},
      processing: false,
      queue: :queue.new()
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:subscribe_batch, channels}, _from, state) do
    request_id = generate_request_id()

    request = %{
      id: request_id,
      channels: channels,
      status: %{
        completed: 0,
        pending: length(channels),
        failed: 0,
        total: length(channels)
      },
      cancelled: false
    }

    new_state = %{
      state
      | requests: Map.put(state.requests, request_id, request),
        queue: :queue.in(request_id, state.queue)
    }

    # Start processing if not already running
    final_state =
      if state.processing do
        new_state
      else
        send(self(), :process_queue)
        %{new_state | processing: true}
      end

    {:reply, {:ok, request_id}, final_state}
  end

  @impl true
  def handle_call({:get_status, request_id}, _from, state) do
    case Map.get(state.requests, request_id) do
      nil -> {:reply, {:error, :not_found}, state}
      request -> {:reply, {:ok, request.status}, state}
    end
  end

  @impl true
  def handle_call({:cancel_batch, request_id}, _from, state) do
    case Map.get(state.requests, request_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      request ->
        updated_request = %{request | cancelled: true}
        new_state = %{state | requests: Map.put(state.requests, request_id, updated_request)}
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call(:get_all_statuses, _from, state) do
    statuses = Map.new(state.requests, fn {id, req} -> {id, req.status} end)
    {:reply, {:ok, statuses}, state}
  end

  @impl true
  def handle_info(:process_queue, state) do
    case :queue.out(state.queue) do
      {{:value, request_id}, new_queue} ->
        state = %{state | queue: new_queue}

        case Map.get(state.requests, request_id) do
          nil ->
            # Request was removed, continue processing
            send(self(), :process_queue)
            {:noreply, state}

          %{cancelled: true} ->
            # Skip cancelled request
            send(self(), :process_queue)
            {:noreply, state}

          request ->
            # Process this request
            new_state = process_request(request, state)

            # Check if request still has pending channels
            updated_request = Map.get(new_state.requests, request_id)

            final_state =
              if updated_request && updated_request.status.pending > 0 do
                # Re-queue the request for remaining channels
                %{new_state | queue: :queue.in(request_id, new_state.queue)}
              else
                new_state
              end

            # Schedule next batch processing after delay
            Process.send_after(self(), :process_queue, state.batch_delay)
            {:noreply, final_state}
        end

      {:empty, _} ->
        # Queue is empty, stop processing
        {:noreply, %{state | processing: false}}
    end
  end

  ## Private Functions

  defp process_request(request, state) do
    pending_channels = get_pending_channels(request)

    if pending_channels == [] do
      state
    else
      # Take batch_size channels
      {batch, _remaining} = Enum.split(pending_channels, state.batch_size)

      # Subscribe to the batch
      case DeribitAdapter.subscribe(state.adapter, batch) do
        {:ok, _} ->
          # Update request status
          completed = request.status.completed + length(batch)
          pending = request.status.pending - length(batch)

          updated_status = %{request.status | completed: completed, pending: pending}

          updated_request = %{request | status: updated_status}

          Logger.info("Batch subscription progress: #{completed}/#{request.status.total}")

          %{state | requests: Map.put(state.requests, request.id, updated_request)}

        {:error, reason} ->
          # Mark batch as failed
          failed = request.status.failed + length(batch)
          pending = request.status.pending - length(batch)

          updated_status = %{request.status | failed: failed, pending: pending}

          updated_request = %{request | status: updated_status}

          Logger.error("Batch subscription failed: #{inspect(reason)}")

          %{state | requests: Map.put(state.requests, request.id, updated_request)}
      end
    end
  end

  defp get_pending_channels(request) do
    completed_count = request.status.completed
    failed_count = request.status.failed
    already_processed = completed_count + failed_count

    Enum.drop(request.channels, already_processed)
  end

  defp generate_request_id do
    "req_" <> (8 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower))
  end
end
