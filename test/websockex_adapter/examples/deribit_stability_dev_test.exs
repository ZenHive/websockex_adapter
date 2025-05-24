defmodule WebsockexAdapter.Examples.DeribitStabilityDevTest do
  @moduledoc """
  1-hour stability test for development and CI environments.

  A shorter version of the 24-hour stability test that can be run
  during development to verify stability improvements.

  Run with: mix test --only stability_dev test/websockex_adapter/examples/deribit_stability_dev_test.exs
  """

  use ExUnit.Case

  alias WebsockexAdapter.Examples.DeribitGenServerAdapter
  alias WebsockexAdapter.Examples.DeribitStabilityTest.StabilityMonitor

  require Logger

  # Import the modules from the main stability test
  Code.require_file("deribit_stability_test.exs", __DIR__)
  @moduletag :stability_dev
  # 65 minutes timeout
  @moduletag timeout: 3_900_000

  # Test configuration
  @test_duration_minutes 60
  @test_duration_ms @test_duration_minutes * 60 * 1000
  @heartbeat_interval_seconds 30
  @subscription_channels [
    # Perpetuals
    "ticker.BTC-PERPETUAL.raw",
    "ticker.ETH-PERPETUAL.raw",
    # BTC Options - subscribe to the most liquid strikes
    "ticker.BTC-*.raw",
    # ETH Options - subscribe to the most liquid strikes
    "ticker.ETH-*.raw"
  ]

  setup do
    # Ensure we have credentials
    client_id = System.get_env("DERIBIT_CLIENT_ID")
    client_secret = System.get_env("DERIBIT_CLIENT_SECRET")

    if is_nil(client_id) or is_nil(client_secret) do
      {:skip, "DERIBIT_CLIENT_ID and DERIBIT_CLIENT_SECRET must be set"}
    end

    %{
      client_id: client_id,
      client_secret: client_secret
    }
  end

  @tag :stability_dev
  test "1-hour continuous operation with heartbeats", %{client_id: client_id, client_secret: client_secret} do
    Logger.info("""

    🚀 === STARTING 1-HOUR STABILITY TEST ===
    Duration: #{@test_duration_minutes} minutes
    Heartbeat interval: #{@heartbeat_interval_seconds} seconds
    Subscriptions: #{inspect(@subscription_channels)}
    =======================================
    """)

    # Start the monitor (adapter will be set later)
    {:ok, monitor} = StabilityMonitor.start_link(nil, self())

    # Create handler function that captures the monitor
    handler_fun = fn message ->
      case message do
        {:message, {:text, text}} ->
          StabilityMonitor.record_message(monitor)

          case Jason.decode(text) do
            {:ok, %{"method" => "heartbeat"}} ->
              StabilityMonitor.record_heartbeat(monitor)

            {:ok, %{"params" => %{"type" => "heartbeat"}}} ->
              # Deribit sends heartbeats as params.type = "heartbeat"
              StabilityMonitor.record_heartbeat(monitor)

            {:ok, %{"params" => %{"type" => "test_request"}}} ->
              # This won't be seen as Client handles it internally
              Logger.debug("❗ Saw test_request (should be handled by Client)")
              StabilityMonitor.record_heartbeat(monitor)

            {:ok, %{"method" => "subscription", "params" => %{"channel" => channel}}} ->
              Logger.debug("📊 Market data: #{channel}")

            {:ok, %{"error" => error}} ->
              StabilityMonitor.record_error(monitor, error)

            {:ok, decoded} ->
              # Log all messages to debug heartbeat format
              Logger.debug("📩 Received message: #{inspect(decoded, limit: :infinity)}")

              # Check if this is a heartbeat response
              case decoded do
                %{"result" => result, "id" => _id} when is_map(result) ->
                  # This might be a response to our heartbeat
                  if Map.has_key?(result, "version") do
                    Logger.info("💚 Heartbeat response received")
                    StabilityMonitor.record_heartbeat(monitor)
                  end

                %{"result" => "ok", "id" => _id} ->
                  # Response from set_heartbeat - ignore it
                  Logger.debug("✅ set_heartbeat response acknowledged")

                _ ->
                  :ok
              end

              :ok

            _ ->
              :ok
          end

        {:protocol_error, reason} ->
          Logger.warning("🔌 WebSocket disconnected: #{inspect(reason)}")
          StabilityMonitor.record_reconnection(monitor)

        _ ->
          :ok
      end
    end

    # Start the adapter with our custom handler
    adapter_opts = [
      client_id: client_id,
      client_secret: client_secret,
      heartbeat_interval: @heartbeat_interval_seconds,
      handler: handler_fun,
      name: :stability_dev_test_adapter
    ]

    {:ok, adapter} = DeribitGenServerAdapter.start_link(adapter_opts)

    # Update monitor with adapter
    StabilityMonitor.set_adapter(monitor, adapter)

    # Wait for connection
    Process.sleep(2_000)

    # Authenticate
    :ok = DeribitGenServerAdapter.authenticate(adapter)
    Process.sleep(1_000)

    # Subscribe to channels
    :ok = DeribitGenServerAdapter.subscribe(adapter, @subscription_channels)

    # Run stability test
    start_time = System.monotonic_time(:millisecond)
    run_stability_test_dev(adapter, monitor, @test_duration_ms)
    actual_runtime = System.monotonic_time(:millisecond) - start_time

    # Get final metrics
    metrics = StabilityMonitor.get_metrics(monitor)

    # Generate report
    generate_dev_report(metrics, actual_runtime)

    # Assertions (more lenient for dev test)
    assert_dev_stability_requirements(metrics)

    # Cleanup
    DeribitGenServerAdapter.unsubscribe(adapter, @subscription_channels)
    GenServer.stop(adapter)
  end

  defp run_stability_test_dev(_adapter, _monitor, remaining_ms) when remaining_ms <= 0 do
    :ok
  end

  defp run_stability_test_dev(adapter, monitor, remaining_ms) do
    # Check every 10 seconds
    check_interval = 10_000

    # Verify adapter is still alive
    if Process.alive?(Process.whereis(:stability_dev_test_adapter)) do
      # Send explicit heartbeat test every check interval
      case DeribitGenServerAdapter.send_request(adapter, "public/test", %{}) do
        :ok ->
          Logger.debug("💚 Manual heartbeat test sent")

        # We'll count the response in the handler

        error ->
          Logger.warning("⚠️  Failed to send heartbeat test: #{inspect(error)}")
          StabilityMonitor.record_error(monitor, error)
      end
    else
      Logger.error("💀 Adapter process died!")
      StabilityMonitor.record_error(monitor, :adapter_died)
    end

    # Sleep and continue
    Process.sleep(min(check_interval, remaining_ms))
    run_stability_test_dev(adapter, monitor, remaining_ms - check_interval)
  end

  defp generate_dev_report(metrics, actual_runtime_ms) do
    runtime_minutes = actual_runtime_ms / (60 * 1000)
    # 2 per minute
    expected_heartbeats = runtime_minutes * 2
    heartbeat_success_rate = metrics.heartbeat_count / max(expected_heartbeats, 1) * 100

    report = """

    📊 === 1-HOUR STABILITY TEST REPORT ===

    Test Duration: #{Float.round(runtime_minutes, 1)} minutes

    Heartbeat Performance:
    - Total heartbeats: #{metrics.heartbeat_count}
    - Expected heartbeats: #{round(expected_heartbeats)}
    - Success rate: #{Float.round(heartbeat_success_rate, 1)}%

    Connection Stability:
    - Reconnections: #{metrics.reconnection_count}
    - Errors: #{metrics.error_count}

    System Resources:
    - Memory (avg): #{StabilityMonitor.format_bytes(metrics.avg_memory_bytes)}
    - Memory (max): #{StabilityMonitor.format_bytes(metrics.max_memory_bytes)}
    - CPU (avg): #{Float.round(metrics.avg_cpu_percent, 1)}%

    Message Processing:
    - Total messages: #{metrics.message_count}
    - Message rate: #{Float.round(metrics.message_count / max(runtime_minutes, 1), 1)}/minute

    #{format_state_metrics(metrics.state_metrics)}
    Result: #{dev_stability_assessment(metrics, expected_heartbeats)}
    =====================================
    """

    Logger.info(report)
  end

  defp format_state_metrics(state_metrics) when map_size(state_metrics) == 0 do
    ""
  end

  defp format_state_metrics(state_metrics) do
    """
    Internal State Growth:
    - Active heartbeats: #{state_metrics.active_heartbeats_growth}
    - Subscriptions: #{state_metrics.subscriptions_growth}
    - Pending requests: #{state_metrics.pending_requests_growth}
    - State memory: #{state_metrics.state_memory_growth} words
    - Process memory: #{StabilityMonitor.format_bytes(state_metrics.process_memory_growth)}
    - Max message queue: #{state_metrics.message_queue_max}
    """
  end

  defp dev_stability_assessment(metrics, expected_heartbeats) do
    heartbeat_success = metrics.heartbeat_count / max(expected_heartbeats, 1)

    cond do
      metrics.error_count == 0 and metrics.reconnection_count == 0 and heartbeat_success > 0.95 ->
        "✅ PASSED - Excellent stability"

      metrics.error_count <= 2 and metrics.reconnection_count <= 1 and heartbeat_success > 0.90 ->
        "✅ PASSED - Good stability"

      true ->
        "❌ FAILED - Stability issues detected"
    end
  end

  defp assert_dev_stability_requirements(metrics) do
    runtime_minutes = metrics.runtime_ms / (60 * 1000)
    expected_heartbeats = runtime_minutes * 2

    # Heartbeat success rate should be > 90% for dev test
    heartbeat_success_rate = metrics.heartbeat_count / max(expected_heartbeats, 1)

    assert heartbeat_success_rate > 0.90,
           "Heartbeat success rate too low: #{Float.round(heartbeat_success_rate * 100, 1)}%"

    # Should have minimal reconnections (< 2 for 1 hour test)
    assert metrics.reconnection_count < 2,
           "Too many reconnections: #{metrics.reconnection_count}"

    # Error count should be very low (< 5 for 1 hour test)
    assert metrics.error_count < 5,
           "Too many errors: #{metrics.error_count}"
  end
end
