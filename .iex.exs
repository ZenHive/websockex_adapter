# WebsockexAdapter Interactive Testing
# ================================
#
# This file sets up an interactive environment for testing WebsockexAdapter library components.
# It provides convenience functions for testing WebSocket connections, subscriptions,
# reconnection logic, heartbeat functionality, and various error scenarios.
#
# Quick Start:
#   iex -S mix
#   WebsockexAdapterTest.quick_test()
require Logger
defmodule WebsockexAdapterTest do
  @moduledoc """
  Interactive testing module for WebsockexAdapter library.

  ## Quick Start

      # Basic connection test
      WebsockexAdapterTest.quick_test()

      # Connect with debug mode
      client = WebsockexAdapterTest.connect_debug()

      # Test heartbeat functionality
      WebsockexAdapterTest.test_heartbeat()

      # Subscribe to channels
      WebsockexAdapterTest.subscribe(client, ["deribit_price_index.btc_usd"])

      # Send custom messages
      WebsockexAdapterTest.send_json(client, %{method: "public/test"})
  """

  alias WebsockexAdapter.{Client, Config}
  alias WebsockexAdapter.Examples.DeribitAdapter

  @deribit_test_url "wss://test.deribit.com/ws/api/v2"

  def connect(opts \\ []) do
    Logger.debug("🔌 Connecting to Deribit test server...")

    case Client.connect(@deribit_test_url, opts) do
      {:ok, client} ->
        Logger.debug("✅ Connected successfully!")
        Logger.debug("   Client PID: #{inspect(client.server_pid)}")
        Logger.debug("   Gun PID: #{inspect(client.gun_pid)}")
        Logger.debug("   Stream: #{inspect(client.stream_ref)}")
        client

      {:error, reason} ->
        Logger.debug("❌ Connection failed: #{inspect(reason)}")
        nil
    end
  end

  def connect_debug(opts \\ []) do
    Logger.debug("🔌 Connecting to Deribit with DEBUG mode enabled...")
    Logger.debug("📝 All messages will be printed to console")

    # Create a debug handler that prints all messages
    debug_handler = WebsockexAdapter.MessageHandler.create_handler(
      on_message: fn
        {:message, {:text, json}} ->
          Logger.debug("\n📨 [TEXT MESSAGE] #{DateTime.utc_now() |> DateTime.to_string()}")
          case Jason.decode(json) do
            {:ok, decoded} ->
              IO.inspect(decoded, label: "   JSON", pretty: true)
            {:error, _} ->
              Logger.debug("   Raw text: #{json}")
          end
          :ok
        {:message, {:binary, data}} ->
          Logger.debug("\n📦 [BINARY MESSAGE] #{DateTime.utc_now() |> DateTime.to_string()}")
          IO.inspect(data, label: "   Binary data", pretty: true)
          :ok
        {:message, other} ->
          Logger.debug("\n📨 [MESSAGE] #{DateTime.utc_now() |> DateTime.to_string()}")
          IO.inspect(other, label: "   Content", pretty: true)
          :ok
        other ->
          Logger.debug("\n🔔 [OTHER] #{DateTime.utc_now() |> DateTime.to_string()}")
          IO.inspect(other, label: "   Data", pretty: true)
          :ok
      end,
      on_upgrade: fn info ->
        Logger.debug("\n🔗 [UPGRADE] WebSocket connection upgraded")
        IO.inspect(info, label: "   Info", pretty: true)
        :ok
      end,
      on_error: fn error ->
        Logger.debug("\n❌ [ERROR] #{DateTime.utc_now() |> DateTime.to_string()}")
        IO.inspect(error, label: "   Error", pretty: true)
        :ok
      end,
      on_down: fn reason ->
        Logger.debug("\n📉 [DOWN] Connection down")
        IO.inspect(reason, label: "   Reason", pretty: true)
        :ok
      end
    )

    connect(Keyword.merge(opts, [handler: debug_handler]))
  end

  def test_automatic_heartbeat(interval \\ 10) do
    Logger.debug("""
    💓 Testing AUTOMATIC Deribit Heartbeat Functionality
    ===================================================
    Using DeribitAdapter with built-in automatic heartbeat responses
    Heartbeat interval: #{interval} seconds
    """)

    # Create debug handler to highlight heartbeat messages
    heartbeat_handler = create_heartbeat_debug_handler()

    # Connect using DeribitAdapter with automatic heartbeat configuration
    Logger.debug("🔌 Connecting with DeribitAdapter (automatic heartbeat enabled)...")

    case DeribitAdapter.connect([
      url: @deribit_test_url,
      handler: heartbeat_handler,
      heartbeat_interval: interval
    ]) do
      {:ok, adapter} ->
        Logger.debug("✅ Connected with automatic heartbeat support!")
        Logger.debug("   Client will automatically respond to test_request messages")

        # Enable server-side heartbeat
        Logger.debug("\n📤 Enabling server-side heartbeat...")
        {:ok, heartbeat_request} = DeribitAdapter.set_heartbeat(%{interval: interval})
        Client.send_message(adapter.client, Jason.encode!(heartbeat_request))

        Logger.debug("\n⏳ Watching automatic heartbeat responses...")
        Logger.debug("   🔍 Look for:")
        Logger.debug("   📨 [HEARTBEAT IN] test_request messages from server")
        Logger.debug("   📤 [HEARTBEAT OUT] automatic public/test responses")
        Logger.debug("   💚 [HEARTBEAT OK] successful heartbeat handling")
        Logger.debug("\n   Press Enter to stop...")

        # Start monitoring heartbeat health
        spawn(fn -> monitor_heartbeat_health(adapter.client) end)

        # Wait for user input
        IO.gets("")

        # Disable heartbeat
        Logger.debug("\n📤 Disabling heartbeat...")
        {:ok, disable_request} = DeribitAdapter.disable_heartbeat()
        Client.send_message(adapter.client, Jason.encode!(disable_request))

        :timer.sleep(1000)

        # Close
        Logger.debug("\n🔌 Closing connection...")
        Client.close(adapter.client)
        Logger.debug("✅ Automatic heartbeat test completed!")

      {:error, reason} ->
        Logger.debug("❌ Connection failed: #{inspect(reason)}")
    end

    :ok
  end

  def test_heartbeat(interval \\ 10) do
    Logger.debug("""
    💓 Testing Manual Heartbeat Functionality (Legacy)
    =================================================
    Setting up heartbeat with #{interval} second interval
    """)

    # Connect with debug mode to see all messages
    client = connect_debug()

    if client do
      # Enable heartbeat on Deribit side
      Logger.debug("\n📤 Enabling server-side heartbeat...")
      {:ok, heartbeat_request} = DeribitAdapter.set_heartbeat(%{interval: interval})
      Client.send_message(client, Jason.encode!(heartbeat_request))

      Logger.debug("\n⏳ Waiting for heartbeat messages...")
      Logger.debug("   You should see:")
      Logger.debug("   1. Regular heartbeat messages with type: 'heartbeat'")
      Logger.debug("   2. test_request messages that trigger automatic responses")
      Logger.debug("   3. The client automatically sending public/test responses")
      Logger.debug("\n   Press Enter to disable heartbeat and close connection...")

      # Wait for user input
      IO.gets("")

      # Disable heartbeat
      Logger.debug("\n📤 Disabling heartbeat...")
      {:ok, disable_request} = DeribitAdapter.disable_heartbeat()
      Client.send_message(client, Jason.encode!(disable_request))

      :timer.sleep(1000)

      # Close
      Logger.debug("\n🔌 Closing connection...")
      Client.close(client)
      Logger.debug("✅ Heartbeat test completed!")
    else
      Logger.debug("❌ Test aborted - connection failed")
    end

    :ok
  end

  def test_heartbeat_with_config do
    Logger.debug("""
    💓 Testing Client-side Heartbeat Configuration
    ==============================================
    """)

    # Connect with heartbeat configuration
    Logger.debug("🔌 Connecting with heartbeat config...")

    {:ok, config} = Config.new(@deribit_test_url)
    {:ok, client} = Client.connect(config,
      handler: create_debug_handler(),
      heartbeat_config: %{
        type: :deribit,
        interval: 10_000,
        test_request_handler: fn ->
          Logger.debug("🔄 [HEARTBEAT] Sending automatic test response")
          {:ok, request} = DeribitAdapter.test_request()
          Jason.encode!(request)
        end
      }
    )

    Logger.debug("✅ Connected with heartbeat configuration!")

    # Enable server-side heartbeat
    Logger.debug("\n📤 Enabling server-side heartbeat...")
    {:ok, heartbeat_request} = DeribitAdapter.set_heartbeat(%{interval: 10})
    Client.send_message(client, Jason.encode!(heartbeat_request))

    Logger.debug("\n⏳ Observing heartbeat behavior for 30 seconds...")
    :timer.sleep(30_000)

    # Disable and close
    {:ok, disable_request} = DeribitAdapter.disable_heartbeat()
    Client.send_message(client, Jason.encode!(disable_request))
    Client.close(client)

    Logger.debug("✅ Heartbeat config test completed!")
  end

  def test_gun_debug do
    Logger.debug("""
    🔫 Testing Complete Gun Debug Flow
    =================================
    This shows the complete Gun connection lifecycle with full debugging:
    - Gun connection establishment
    - WebSocket upgrade process
    - Message flow and processing
    - Heartbeat integration
    - Connection monitoring
    """)

    Logger.debug("🔌 Starting Gun debug connection...")
    Logger.debug("📝 Watch for detailed Gun protocol messages")

    # Create minimal handler to not interfere with Gun debug logs
    minimal_handler = fn _ -> :ok end

    case DeribitAdapter.connect([
      url: @deribit_test_url,
      handler: minimal_handler,
      heartbeat_interval: 15  # 15 second heartbeat for faster demo
    ]) do
      {:ok, adapter} ->
        Logger.debug("\n✅ Connection established - monitoring Gun events...")

        # Send a test message to see WebSocket frame logging
        Logger.debug("\n📤 Sending test message to see Gun WebSocket frame logging...")
        {:ok, test_request} = DeribitAdapter.test_request()
        Client.send_message(adapter.client, Jason.encode!(test_request))

        # Enable heartbeat to see test_request/response cycle
        Logger.debug("\n📤 Enabling heartbeat to see Gun frame exchange...")
        {:ok, heartbeat_request} = DeribitAdapter.set_heartbeat(%{interval: 15})
        Client.send_message(adapter.client, Jason.encode!(heartbeat_request))

        # Subscribe to see more message activity
        Logger.debug("\n📡 Subscribing to channel to see more Gun activity...")
        {:ok, sub_request} = DeribitAdapter.subscribe_request(%{channels: ["deribit_price_index.btc_usd"]})
        Client.send_message(adapter.client, Jason.encode!(sub_request))

        Logger.debug("\n⏳ Observing Gun debug output for 45 seconds...")
        Logger.debug("   🔍 Look for:")
        Logger.debug("   🔫 [GUN OPEN] - Initial connection")
        Logger.debug("   🔗 [GUN UPGRADE] - WebSocket upgrade")
        Logger.debug("   📨 [GUN WS TEXT] - Text frame messages")
        Logger.debug("   💓 [HEARTBEAT DETECTED] - Heartbeat processing")
        Logger.debug("   📤 [HEARTBEAT RESPONSE] - Automatic responses")
        Logger.debug("\n   Press Enter to stop early or wait 45 seconds...")

        # Create a task to wait for user input or timeout
        task = Task.async(fn ->
          IO.gets("")
          :user_stopped
        end)

        # Wait either for user input or 45 seconds
        case Task.yield(task, 45_000) do
          {:ok, :user_stopped} ->
            Logger.debug("\n👤 Stopped by user")
          nil ->
            Task.shutdown(task)
            Logger.debug("\n⏰ 45 second observation period completed")
        end

        # Disable heartbeat
        Logger.debug("\n📤 Disabling heartbeat...")
        {:ok, disable_request} = DeribitAdapter.disable_heartbeat()
        Client.send_message(adapter.client, Jason.encode!(disable_request))

        :timer.sleep(1000)

        # Close connection to see Gun cleanup
        Logger.debug("\n🔌 Closing connection to see Gun cleanup logs...")
        Client.close(adapter.client)

        :timer.sleep(500)

        Logger.debug("✅ Gun debug test completed!")
        Logger.debug("📊 Summary of what you observed:")
        Logger.debug("   - Complete Gun connection establishment")
        Logger.debug("   - WebSocket protocol upgrade")
        Logger.debug("   - Real-time message frame processing")
        Logger.debug("   - Automatic heartbeat request/response cycle")
        Logger.debug("   - Clean connection termination")

      {:error, reason} ->
        Logger.debug("❌ Gun debug test failed: #{inspect(reason)}")
    end

    :ok
  end

  def test_gun_reconnection do
    Logger.debug("""
    🔄 Testing Gun Reconnection Debug Flow
    =====================================
    This will show Gun reconnection with full debugging
    """)

    case DeribitAdapter.connect([
      url: @deribit_test_url,
      heartbeat_interval: 10
    ]) do
      {:ok, adapter} ->
        Logger.debug("✅ Initial connection established")
        Logger.debug("📍 Gun PID: #{inspect(adapter.client.gun_pid)}")
        Logger.debug("📍 Client GenServer PID: #{inspect(adapter.client.server_pid)}")

        Logger.debug("\n💥 Killing Gun process to trigger reconnection...")
        Logger.debug("   Watch for:")
        Logger.debug("   💀 [PROCESS DOWN] - Gun process termination")
        Logger.debug("   🔄 [GUN RECONNECT] - Reconnection attempt")
        Logger.debug("   🔫 [GUN OPEN] - New connection establishment")
        Logger.debug("   🔗 [GUN UPGRADE] - New WebSocket upgrade")

        # Kill the Gun process
        Process.exit(adapter.client.gun_pid, :kill)

        Logger.debug("\n⏳ Waiting 15 seconds to observe reconnection...")
        :timer.sleep(15_000)

        # Check if we have a new Gun PID
        new_state = Client.get_state(adapter.client)
        Logger.debug("\n📊 Reconnection Result:")
        Logger.debug("   🔄 Connection State: #{new_state}")

        if new_state == :connected do
          Logger.debug("   ✅ Reconnection successful!")
        else
          Logger.debug("   ⏳ Reconnection in progress or failed")
        end

        # Clean close
        :timer.sleep(2000)
        Client.close(adapter.client)
        Logger.debug("✅ Gun reconnection test completed!")

      {:error, reason} ->
        Logger.debug("❌ Reconnection test failed: #{inspect(reason)}")
    end

    :ok
  end

  def quick_test do
    Logger.debug("""
    🚀 Running WebsockexAdapter Quick Test
    ==================================
    """)

    # Connect
    client = connect()

    if client do
      # Test basic message
      Logger.debug("\n📤 Sending test message...")
      send_json(client, %{
        "jsonrpc" => "2.0",
        "method" => "public/test",
        "params" => %{},
        "id" => 1
      })

      # Subscribe to a channel
      Logger.debug("\n📡 Subscribing to BTC price index...")
      subscribe(client, ["deribit_price_index.btc_usd"])

      # Wait a bit to see some messages
      Logger.debug("\n⏳ Waiting 5 seconds to observe messages...")
      :timer.sleep(5000)

      # Close
      Logger.debug("\n🔌 Closing connection...")
      Client.close(client)
      Logger.debug("✅ Test completed!")
    else
      Logger.debug("❌ Test aborted - connection failed")
    end

    :ok
  end

  def subscribe(client, channels) when is_list(channels) do
    Logger.debug("📡 Subscribing to channels: #{inspect(channels)}")

    # Use DeribitAdapter for proper subscription format
    {:ok, request} = DeribitAdapter.subscribe_request(%{channels: channels})
    json = Jason.encode!(request)

    case Client.send_message(client, json) do
      :ok ->
        Logger.debug("✅ Subscription request sent")
        :ok

      {:error, reason} ->
        Logger.debug("❌ Subscription failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def send_json(client, message) when is_map(message) do
    json = Jason.encode!(message)
    Logger.debug("📤 Sending JSON: #{json}")

    case Client.send_message(client, json) do
      :ok ->
        Logger.debug("✅ Message sent")
        :ok

      {:error, reason} ->
        Logger.debug("❌ Send failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def test_error_scenarios do
    Logger.debug("🧪 Testing error scenarios...")

    # Test invalid URL
    Logger.debug("\n1. Testing invalid URL...")
    {:error, reason} = Client.connect("not-a-url")
    Logger.debug("   ✅ Got expected error: #{inspect(reason)}")

    # Test connection timeout
    Logger.debug("\n2. Testing connection timeout...")
    {:error, reason} = Client.connect(@deribit_test_url, timeout: 1)
    Logger.debug("   ✅ Got expected error: #{inspect(reason)}")

    # Test send on disconnected client
    Logger.debug("\n3. Testing send on closed connection...")
    {:ok, client} = Client.connect(@deribit_test_url)
    Client.close(client)
    :timer.sleep(100)
    result = Client.send_message(client, "test")
    Logger.debug("   ✅ Got expected result: #{inspect(result)}")

    Logger.debug("\n✅ All error scenarios passed!")
  end

  def monitor_connection(client) do
    Logger.debug("👁️  Monitoring connection state...")
    spawn(fn ->
      monitor_loop(client)
    end)
  end

  defp monitor_loop(client) do
    state = Client.get_state(client)
    Logger.debug("[#{DateTime.utc_now() |> DateTime.to_string()}] Connection state: #{state}")
    :timer.sleep(5000)
    monitor_loop(client)
  end

  def test_internal_reconnection do
    Logger.debug("🔄 Testing internal reconnection...")
    Logger.debug("Note: Client GenServer now handles reconnection internally")
    Logger.debug("Kill the Gun process and watch the Client reconnect automatically")

    client = connect_debug()
    if client do
      Logger.debug("📍 Client GenServer PID: #{inspect(client.server_pid)}")
      Logger.debug("📍 Gun PID: #{inspect(client.gun_pid)}")
      Logger.debug("\nTry: Process.exit(client.gun_pid, :kill)")
      Logger.debug("Then check: Client.get_state(client)")
      Logger.debug("\nMonitoring connection state...")
      monitor_connection(client)
      client
    end
  end

  def close(client) when is_map(client) do
    Logger.debug("🔌 Closing connection...")
    Client.close(client)
    Logger.debug("✅ Connection closed")
    :ok
  end

  defp create_debug_handler do
    WebsockexAdapter.MessageHandler.create_handler(
      on_message: fn
        {:message, {:text, json}} ->
          Logger.debug("\n📨 [TEXT MESSAGE] #{DateTime.utc_now() |> DateTime.to_string()}")
          case Jason.decode(json) do
            {:ok, decoded} ->
              IO.inspect(decoded, label: "   JSON", pretty: true)
            {:error, _} ->
              Logger.debug("   Raw text: #{json}")
          end
          :ok
        {:message, {:binary, data}} ->
          Logger.debug("\n📦 [BINARY MESSAGE] #{DateTime.utc_now() |> DateTime.to_string()}")
          IO.inspect(data, label: "   Binary data", pretty: true)
          :ok
        {:message, other} ->
          Logger.debug("\n📨 [MESSAGE] #{DateTime.utc_now() |> DateTime.to_string()}")
          IO.inspect(other, label: "   Content", pretty: true)
          :ok
        other ->
          Logger.debug("\n🔔 [OTHER] #{DateTime.utc_now() |> DateTime.to_string()}")
          IO.inspect(other, label: "   Data", pretty: true)
          :ok
      end,
      on_error: fn error ->
        Logger.debug("\n❌ [ERROR] #{DateTime.utc_now() |> DateTime.to_string()}")
        IO.inspect(error, label: "   Error", pretty: true)
        :ok
      end
    )
  end

  defp create_heartbeat_debug_handler do
    WebsockexAdapter.MessageHandler.create_handler(
      on_message: fn
        {:message, {:text, json}} ->
          timestamp = DateTime.utc_now() |> DateTime.to_string()

          case Jason.decode(json) do
            {:ok, %{"method" => "heartbeat", "params" => %{"type" => "test_request"}} = decoded} ->
              Logger.debug("\n💓 [HEARTBEAT IN] #{timestamp}")
              Logger.debug("   🚨 test_request received - Client will auto-respond!")
              IO.inspect(decoded, label: "   Heartbeat data", pretty: true)

            {:ok, %{"method" => "public/test"} = decoded} ->
              Logger.debug("\n📤 [HEARTBEAT OUT] #{timestamp}")
              Logger.debug("   ✅ Automatic heartbeat response sent")
              IO.inspect(decoded, label: "   Response data", pretty: true)

            {:ok, %{"method" => "heartbeat"} = decoded} ->
              Logger.debug("\n💚 [HEARTBEAT OK] #{timestamp}")
              Logger.debug("   💗 Heartbeat acknowledged")
              IO.inspect(decoded, label: "   Heartbeat data", pretty: true)

            {:ok, decoded} ->
              Logger.debug("\n📨 [MESSAGE] #{timestamp}")
              IO.inspect(decoded, label: "   JSON", pretty: true)

            {:error, _} ->
              Logger.debug("\n📨 [TEXT] #{timestamp}")
              Logger.debug("   Raw text: #{json}")
          end
          :ok

        {:message, other} ->
          Logger.debug("\n📨 [MESSAGE] #{DateTime.utc_now() |> DateTime.to_string()}")
          IO.inspect(other, label: "   Content", pretty: true)
          :ok

        other ->
          Logger.debug("\n🔔 [OTHER] #{DateTime.utc_now() |> DateTime.to_string()}")
          IO.inspect(other, label: "   Data", pretty: true)
          :ok
      end,
      on_error: fn error ->
        Logger.debug("\n❌ [ERROR] #{DateTime.utc_now() |> DateTime.to_string()}")
        IO.inspect(error, label: "   Error", pretty: true)
        :ok
      end
    )
  end

  defp monitor_heartbeat_health(client) do
    :timer.sleep(5000)

    try do
      health = Client.get_heartbeat_health(client)
      if health do
        Logger.debug("\n💚 [HEARTBEAT HEALTH] #{DateTime.utc_now() |> DateTime.to_string()}")
        IO.inspect(health, label: "   Health metrics", pretty: true)
      end
    rescue
      _ -> :ok  # Client might not support heartbeat health yet
    end

    monitor_heartbeat_health(client)
  end

  def help do
    Logger.debug("""
    WebsockexAdapter Interactive Testing with Heartbeat Support
    =======================================================

    Quick Start:
      client = WebsockexAdapterTest.connect()
      WebsockexAdapterTest.quick_test()

    Debug Mode (see all messages):
      client = WebsockexAdapterTest.connect_debug()
      WebsockexAdapterTest.test_heartbeat()

    Heartbeat Testing:
      WebsockexAdapterTest.test_automatic_heartbeat()            # Test automatic heartbeat (RECOMMENDED)
      WebsockexAdapterTest.test_automatic_heartbeat(5)           # Test with 5 second interval
      WebsockexAdapterTest.test_heartbeat()                      # Test manual heartbeat (legacy)
      WebsockexAdapterTest.test_heartbeat_with_config()          # Test client-side config

    Gun Protocol Debugging:
      WebsockexAdapterTest.test_gun_debug()                      # Complete Gun connection debug flow
      WebsockexAdapterTest.test_gun_reconnection()               # Gun reconnection debug flow

    Connection Management:
      WebsockexAdapterTest.connect()                             # Connect with defaults
      WebsockexAdapterTest.connect_debug()                       # Connect with debug output
      WebsockexAdapterTest.connect(timeout: 10_000)              # Connect with options
      WebsockexAdapterTest.close(client)                         # Close connection

    Message Operations:
      WebsockexAdapterTest.send_json(client, %{method: "test"})  # Send JSON message
      WebsockexAdapterTest.subscribe(client, ["channel"])        # Subscribe to channels

    Testing & Monitoring:
      WebsockexAdapterTest.test_error_scenarios()                # Test error handling
      WebsockexAdapterTest.monitor_connection(client)            # Monitor connection state
      WebsockexAdapterTest.test_internal_reconnection()          # Test auto-reconnection

    Direct API:
      WebsockexAdapter.Client.connect("wss://...")               # Direct client connection
      DeribitAdapter.set_heartbeat(%{interval: 10})          # Get heartbeat request
      DeribitAdapter.test_request()                          # Get test request

    Tips:
      - Use test_automatic_heartbeat() to see automatic heartbeat responses
      - Use test_gun_debug() to see complete Gun protocol flow
      - DeribitAdapter.connect() enables automatic heartbeat handling
      - test_request messages trigger instant automatic responses
      - Heartbeat health is monitored and displayed in real-time
      - Kill Gun process to test reconnection: Process.exit(client.gun_pid, :kill)
      - Look for 💓 [HEARTBEAT IN] and 📤 [HEARTBEAT OUT] messages
      - Look for 🔫 [GUN OPEN] and 🔗 [GUN UPGRADE] for connection flow
      - Look for 📨 [GUN WS TEXT] for WebSocket frame activity
    """)
  end
end

# Print help on startup
WebsockexAdapterTest.help()
