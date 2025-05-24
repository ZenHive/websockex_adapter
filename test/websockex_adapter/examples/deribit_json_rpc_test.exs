defmodule WebsockexAdapter.Examples.DeribitJsonRpcTest do
  use ExUnit.Case, async: false

  alias WebsockexAdapter.Examples.DeribitAdapter

  @moduletag :integration

  describe "JSON-RPC macro-generated methods" do
    test "market data methods generate correct JSON-RPC structure" do
      # Test get_instruments
      {:ok, request} = DeribitAdapter.get_instruments(%{currency: "BTC", kind: "future"})
      assert request["method"] == "public/get_instruments"
      assert request["params"] == %{currency: "BTC", kind: "future"}
      assert request["jsonrpc"] == "2.0"
      assert is_integer(request["id"])

      # Test get_order_book
      {:ok, request} = DeribitAdapter.get_order_book(%{instrument_name: "BTC-PERPETUAL"})
      assert request["method"] == "public/get_order_book"
      assert request["params"] == %{instrument_name: "BTC-PERPETUAL"}

      # Test ticker
      {:ok, request} = DeribitAdapter.ticker(%{instrument_name: "BTC-PERPETUAL"})
      assert request["method"] == "public/ticker"
      assert request["params"] == %{instrument_name: "BTC-PERPETUAL"}
    end

    test "trading methods generate correct JSON-RPC structure" do
      # Test buy order
      {:ok, request} =
        DeribitAdapter.buy(%{
          instrument_name: "BTC-PERPETUAL",
          amount: 10,
          type: "limit",
          price: 50_000
        })

      assert request["method"] == "private/buy"
      assert request["params"].instrument_name == "BTC-PERPETUAL"
      assert request["params"].amount == 10

      # Test cancel order
      {:ok, request} = DeribitAdapter.cancel(%{order_id: "12345"})
      assert request["method"] == "private/cancel"
      assert request["params"] == %{order_id: "12345"}

      # Test get_open_orders
      {:ok, request} = DeribitAdapter.get_open_orders(%{currency: "BTC"})
      assert request["method"] == "private/get_open_orders"
      assert request["params"] == %{currency: "BTC"}
    end

    test "session management methods generate correct JSON-RPC structure" do
      # Test set_heartbeat
      {:ok, request} = DeribitAdapter.set_heartbeat(%{interval: 30})
      assert request["method"] == "public/set_heartbeat"
      assert request["params"] == %{interval: 30}

      # Test enable_cancel_on_disconnect
      {:ok, request} = DeribitAdapter.enable_cancel_on_disconnect()
      assert request["method"] == "private/enable_cancel_on_disconnect"
      assert request["params"] == %{}
    end

    @tag timeout: 120_000
    test "macro-generated methods work with real Deribit test API" do
      # Connect to Deribit test API
      {:ok, adapter} = DeribitAdapter.connect(url: "wss://test.deribit.com/ws/api/v2")

      # Test public method: get_instruments
      {:ok, request} = DeribitAdapter.get_instruments(%{currency: "BTC", kind: "future"})
      {:ok, _response} = WebsockexAdapter.Client.send_message(adapter.client, Jason.encode!(request))

      # Give time for response
      Process.sleep(1000)

      # Test public method: ticker
      {:ok, request} = DeribitAdapter.ticker(%{instrument_name: "BTC-PERPETUAL"})
      {:ok, _response} = WebsockexAdapter.Client.send_message(adapter.client, Jason.encode!(request))

      Process.sleep(1000)

      # Test heartbeat setup
      {:ok, request} = DeribitAdapter.set_heartbeat(%{interval: 30})
      {:ok, _response} = WebsockexAdapter.Client.send_message(adapter.client, Jason.encode!(request))

      Process.sleep(1000)

      # Close connection
      :ok = WebsockexAdapter.Client.close(adapter.client)
    end
  end

  describe "market making workflow patterns" do
    test "order placement workflow using macro-generated methods" do
      # This demonstrates the typical workflow for market makers

      # Step 1: Get current order book
      {:ok, orderbook_request} =
        DeribitAdapter.get_order_book(%{
          instrument_name: "BTC-PERPETUAL",
          depth: 10
        })

      # Step 2: Place limit orders on both sides
      {:ok, buy_request} =
        DeribitAdapter.buy(%{
          instrument_name: "BTC-PERPETUAL",
          amount: 10,
          type: "limit",
          price: 50_000,
          post_only: true
        })

      {:ok, sell_request} =
        DeribitAdapter.sell(%{
          instrument_name: "BTC-PERPETUAL",
          amount: 10,
          type: "limit",
          price: 51_000,
          post_only: true
        })

      # Step 3: Monitor open orders
      {:ok, open_orders_request} =
        DeribitAdapter.get_open_orders_by_instrument(%{
          instrument_name: "BTC-PERPETUAL"
        })

      # All requests have proper JSON-RPC structure
      assert orderbook_request["method"] == "public/get_order_book"
      assert buy_request["method"] == "private/buy"
      assert sell_request["method"] == "private/sell"
      assert open_orders_request["method"] == "private/get_open_orders_by_instrument"
    end

    test "risk management workflow using macro-generated methods" do
      # Typical risk monitoring workflow

      # Step 1: Get account summary
      {:ok, account_request} =
        DeribitAdapter.get_account_summary(%{
          currency: "BTC",
          extended: true
        })

      # Step 2: Check positions
      {:ok, positions_request} =
        DeribitAdapter.get_positions(%{
          currency: "BTC"
        })

      # Step 3: Cancel all orders if risk threshold exceeded
      {:ok, cancel_all_request} =
        DeribitAdapter.cancel_all(%{
          currency: "BTC"
        })

      assert account_request["method"] == "private/get_account_summary"
      assert positions_request["method"] == "private/get_positions"
      assert cancel_all_request["method"] == "private/cancel_all"
    end
  end
end
