defmodule WebsockexAdapter.ClientTest do
  use ExUnit.Case

  alias WebsockexAdapter.Client
  alias WebsockexAdapter.Config

  @deribit_test_url "wss://test.deribit.com/ws/api/v2"

  test "connect to test.deribit.com with URL string" do
    {:ok, client} = Client.connect(@deribit_test_url)

    assert client.gun_pid != nil
    assert client.stream_ref != nil
    assert client.state == :connected
    assert client.url == @deribit_test_url

    Client.close(client)
  end

  test "connect with config struct" do
    {:ok, config} = Config.new(@deribit_test_url, timeout: 10_000)
    {:ok, client} = Client.connect(config)

    assert client.gun_pid != nil
    assert client.stream_ref != nil
    assert client.state == :connected
    assert client.url == @deribit_test_url

    Client.close(client)
  end

  test "connect with invalid URL returns error" do
    {:error, "Invalid URL format"} = Client.connect("http://example.com")
  end

  test "connect with invalid config options returns error" do
    {:error, "Timeout must be positive"} = Client.connect(@deribit_test_url, timeout: 0)
  end

  test "get_state returns current state" do
    {:ok, client} = Client.connect(@deribit_test_url)

    assert Client.get_state(client) == :connected

    Client.close(client)
  end

  test "send_message when connected succeeds" do
    {:ok, client} = Client.connect(@deribit_test_url)

    result = Client.send_message(client, "test")
    assert :ok == result

    Client.close(client)
  end

  test "subscribe formats message correctly" do
    {:ok, client} = Client.connect(@deribit_test_url)

    result = Client.subscribe(client, ["deribit_price_index.btc_usd"])
    assert :ok == result

    Client.close(client)
  end

  describe "GenServer implementation" do
    test "client struct includes server_pid" do
      {:ok, client} = Client.connect(@deribit_test_url)

      assert is_pid(client.server_pid)
      assert Process.alive?(client.server_pid)

      Client.close(client)
    end

    test "closing client stops GenServer process" do
      {:ok, client} = Client.connect(@deribit_test_url)
      server_pid = client.server_pid

      assert Process.alive?(server_pid)
      Client.close(client)

      # Give the process time to stop
      Process.sleep(100)
      refute Process.alive?(server_pid)
    end

    test "multiple clients can run concurrently" do
      {:ok, client1} = Client.connect(@deribit_test_url)
      {:ok, client2} = Client.connect(@deribit_test_url)

      assert client1.server_pid != client2.server_pid
      assert Process.alive?(client1.server_pid)
      assert Process.alive?(client2.server_pid)

      Client.close(client1)
      Client.close(client2)
    end

    test "GenServer handles connection errors properly" do
      # Use a very short timeout
      config = Config.new!(@deribit_test_url, timeout: 1)

      # Should get either timeout or connection_failed
      assert {:error, reason} = Client.connect(config)
      assert reason in [:timeout, :connection_failed]
    end

    test "client operations work through GenServer calls" do
      {:ok, client} = Client.connect(@deribit_test_url)

      # Test that operations go through GenServer
      assert Client.get_state(client) == :connected
      assert :ok = Client.send_message(client, "test")

      Client.close(client)
    end

    test "Gun sends messages to Client GenServer process" do
      {:ok, client} = Client.connect(@deribit_test_url)

      # Send a test message that should trigger a response
      test_request =
        Jason.encode!(%{
          "jsonrpc" => "2.0",
          "method" => "public/test",
          "params" => %{},
          "id" => 1
        })

      # The Client GenServer should handle the response with correlation
      assert {:ok, %{"id" => 1, "result" => %{"version" => _}}} = Client.send_message(client, test_request)

      # Give time for response
      Process.sleep(100)

      # Verify the GenServer is still alive (didn't crash from unhandled messages)
      assert Process.alive?(client.server_pid)

      Client.close(client)
    end

    @tag :skip
    test "reconnection maintains Gun message ownership in Client GenServer" do
      # This test requires simulating a connection drop
      # Would need to either:
      # 1. Kill the Gun process and verify reconnection
      # 2. Use a mock server that can drop connections
      # For now, marking as skip since it requires infrastructure changes
    end
  end
end
