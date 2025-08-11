defmodule ZenWebsocket.Examples.BasicUsageTest do
  use ExUnit.Case, async: false

  alias ZenWebsocket.Client
  alias ZenWebsocket.Config
  alias ZenWebsocket.Examples.Docs.BasicUsage

  @moduletag :integration
  @echo_server "wss://echo.websocket.org"

  describe "echo_server_example/0" do
    @tag timeout: 10_000
    test "demonstrates basic echo server connection from docs" do
      # Run the example function
      assert {:ok, client} = BasicUsage.echo_server_example()

      # Verify we received a message (echo server may send different responses)
      assert_receive {:websocket_message, _message}, 5_000

      # Client should already be closed by the example
      refute Process.alive?(client.server_pid)
    end
  end

  describe "custom_headers_example/1" do
    @tag timeout: 10_000
    test "demonstrates connection with custom headers" do
      # Run the example with a test token
      assert {:ok, client} = BasicUsage.custom_headers_example("test-token-123")

      # Verify connection was established
      assert Client.get_state(client) == :connected

      # Clean up
      assert :ok = Client.close(client)
    end
  end

  describe "basic usage patterns" do
    @tag timeout: 10_000
    test "simple connection and message exchange" do
      assert {:ok, client} = Client.connect(@echo_server)

      # Send a message
      assert :ok = Client.send_message(client, "test message")

      # Receive the echo
      assert_receive {:websocket_message, "test message"}, 5_000

      assert :ok = Client.close(client)
    end

    @tag timeout: 10_000
    test "multiple messages in sequence" do
      assert {:ok, client} = Client.connect(@echo_server)

      # Send multiple messages
      messages = ["first", "second", "third"]

      for msg <- messages do
        assert :ok = Client.send_message(client, msg)
      end

      # Receive all echoes
      for msg <- messages do
        assert_receive {:websocket_message, ^msg}, 5_000
      end

      assert :ok = Client.close(client)
    end

    @tag timeout: 10_000
    test "connection with custom configuration" do
      config = %Config{
        url: @echo_server,
        headers: [
          {"User-Agent", "ZenWebsocket Test"},
          {"X-Test-Header", "test-value"}
        ],
        timeout: 10_000,
        retry_count: 3
      }

      assert {:ok, client} = Client.connect(config)
      assert Client.get_state(client) == :connected

      # Test message exchange
      assert :ok = Client.send_message(client, "config test")
      assert_receive {:websocket_message, "config test"}, 5_000

      assert :ok = Client.close(client)
    end

    @tag timeout: 15_000
    test "parallel connections work independently" do
      assert {:ok, client1} = Client.connect(@echo_server)
      assert {:ok, client2} = Client.connect(@echo_server)

      # Send different messages from each client
      assert :ok = Client.send_message(client1, "from client 1")
      assert :ok = Client.send_message(client2, "from client 2")

      # Each should receive its own echo
      assert_receive {:websocket_message, "from client 1"}, 5_000
      assert_receive {:websocket_message, "from client 2"}, 5_000

      assert :ok = Client.close(client1)
      assert :ok = Client.close(client2)
    end

    @tag timeout: 10_000
    test "handles large messages" do
      assert {:ok, client} = Client.connect(@echo_server)

      # Create a large message (10KB)
      large_message = String.duplicate("x", 10_000)

      assert :ok = Client.send_message(client, large_message)
      assert_receive {:websocket_message, ^large_message}, 5_000

      assert :ok = Client.close(client)
    end

    @tag timeout: 10_000
    test "validates invalid URLs" do
      assert {:error, _} = Client.connect("not-a-websocket-url")
      # Wrong protocol
      assert {:error, _} = Client.connect("http://example.com")
    end
  end
end
