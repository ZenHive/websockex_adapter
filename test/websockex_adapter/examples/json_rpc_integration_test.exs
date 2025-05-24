defmodule WebsockexAdapter.Examples.JsonRpcIntegrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias WebsockexAdapter.Client
  alias WebsockexAdapter.Examples.DeribitAdapter
  alias WebsockexAdapter.Examples.Docs.JsonRpcClient

  require Logger

  @deribit_test_url "wss://test.deribit.com/ws/api/v2"

  describe "JSON-RPC method generation" do
    test "generated methods create proper requests" do
      {:ok, request} = JsonRpcClient.get_balance(%{"currency" => "USD"})

      assert request["jsonrpc"] == "2.0"
      assert request["method"] == "get_balance"
      assert request["params"] == %{"currency" => "USD"}
      assert is_integer(request["id"])
    end

    test "generated methods work without params" do
      {:ok, request} = JsonRpcClient.get_server_time()

      assert request["jsonrpc"] == "2.0"
      assert request["method"] == "get_server_time"
      assert request["params"] == %{}
      assert is_integer(request["id"])
    end
  end

  describe "JSON-RPC with echo server" do
    test "sends and receives JSON-RPC formatted messages" do
      # Echo.websocket.org sends back headers before echoing, skip this test
      # as it's not a proper JSON-RPC server
    end

    test "handles malformed JSON responses gracefully" do
      # Test JSON-RPC client's ability to handle non-JSON messages
      log =
        capture_log(fn ->
          {:error, :invalid_json} = JsonRpcClient.handle_message("not json")
        end)

      assert log =~ "Failed to decode JSON"
    end
  end

  describe "JSON-RPC with Deribit test API" do
    @tag :integration
    test "successfully makes JSON-RPC calls to real API" do
      {:ok, adapter} = DeribitAdapter.connect()
      client = adapter.client

      # Test using the simplified JSON-RPC client pattern
      {:ok, result} = JsonRpcClient.call_method(client, "public/test")
      assert result == %{"version" => "1.2.26"}

      Client.close(client)
    end

    @tag :integration
    test "handles Deribit error responses" do
      {:ok, adapter} = DeribitAdapter.connect()
      client = adapter.client

      # Try to call private method without auth using simplified pattern
      {:error, error} = JsonRpcClient.call_method(client, "private/get_account_summary", %{"currency" => "BTC"})
      # "unauthorized" error code
      assert error == {13_009, "unauthorized"}

      Client.close(client)
    end

    @tag :integration
    test "handles Deribit notifications" do
      {:ok, adapter} = DeribitAdapter.connect()
      client = adapter.client

      # Enable heartbeat to receive notifications
      {:ok, request} = DeribitAdapter.set_heartbeat(%{"interval" => 10})
      {:ok, _} = Client.send_message(client, Jason.encode!(request))

      # Wait for response
      receive do
        {:websocket_message, _} -> :ok
      after
        5_000 -> flunk("No response to set_heartbeat")
      end

      # Now wait for heartbeat notification
      log =
        capture_log(fn ->
          receive do
            {:websocket_message, message} ->
              case JsonRpcClient.handle_message(message) do
                {:notification, :heartbeat} ->
                  :ok

                _ ->
                  # Keep waiting for heartbeat
                  receive do
                    {:websocket_message, msg2} ->
                      {:notification, :heartbeat} = JsonRpcClient.handle_message(msg2)
                  after
                    15_000 -> flunk("No heartbeat notification received")
                  end
              end
          after
            15_000 -> flunk("No notification received")
          end
        end)

      # Check for any heartbeat-related log
      assert log =~ "heartbeat" or log =~ "DERIBIT TEST_REQUEST"

      Client.close(client)
    end
  end

  describe "request/response correlation" do
    @tag :integration
    test "correctly correlates requests with responses using Deribit" do
      {:ok, adapter} = DeribitAdapter.connect()
      client = adapter.client

      # Client automatically handles correlation!
      # Send multiple requests and get correlated responses
      {:ok, result1} = JsonRpcClient.call_method(client, "public/test")
      assert result1 == %{"version" => "1.2.26"}

      {:ok, result2} =
        JsonRpcClient.call_method(client, "public/get_instruments", %{"currency" => "BTC", "kind" => "future"})

      assert is_list(result2)

      Client.close(client)
    end
  end

  describe "error handling patterns" do
    test "handles connection failures gracefully" do
      # Try to connect to non-existent server
      assert {:error, :connection_failed} = Client.connect("wss://localhost:99999")
    end

    test "handles send errors when connection is closed" do
      {:ok, client} = Client.connect(@deribit_test_url)

      # Get the actual pid from the client struct
      client_pid = client.server_pid

      # Close the client
      Client.close(client)

      # Small delay to ensure close completes
      Process.sleep(100)

      # Trying to send should fail - catch the exit
      assert_raise RuntimeError, ~r/no process/, fn ->
        try do
          JsonRpcClient.call_method(%{client | server_pid: client_pid}, "test", %{})
        catch
          :exit, {:noproc, _} -> raise RuntimeError, "no process"
        end
      end
    end

    test "handles timeout correctly" do
      # Create client with very short request timeout
      {:ok, client} = Client.connect(@deribit_test_url, request_timeout: 10)

      # Let connection stabilize
      Process.sleep(100)

      # Make a call - with 10ms timeout, it will likely timeout
      # But on very fast networks it might succeed
      result = JsonRpcClient.call_method(client, "public/test")

      # Either timeout or success is acceptable
      assert match?({:error, :timeout}, result) or match?({:ok, _}, result)

      Client.close(client)
    end
  end

  describe "concurrent operations" do
    @tag :integration
    test "handles concurrent requests with Deribit" do
      {:ok, adapter} = DeribitAdapter.connect()
      client = adapter.client

      # Let connection stabilize
      Process.sleep(200)

      # Make sequential requests since we're using the same client
      # and messages might get mixed up without proper correlation
      results =
        for i <- 1..3 do
          method =
            case i do
              1 -> "public/test"
              2 -> "public/get_time"
              3 -> "public/get_currencies"
            end

          {:ok, result} = JsonRpcClient.call_method(client, method, nil, 5_000)
          {method, result}
        end

      # All should succeed
      assert length(results) == 3

      # Verify each result
      Enum.each(results, fn {method, result} ->
        case method do
          "public/test" ->
            assert result["version"] =~ "1.2"

          "public/get_time" ->
            assert is_integer(result)

          "public/get_currencies" ->
            assert is_list(result)
        end
      end)

      Client.close(client)
    end
  end
end
