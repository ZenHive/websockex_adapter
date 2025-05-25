defmodule WebsockexAdapter.Examples.DeribitRpcTest do
  use ExUnit.Case

  alias WebsockexAdapter.Examples.DeribitRpc

  describe "build_request/2" do
    test "creates valid JSON-RPC request with method and params" do
      request = DeribitRpc.build_request("test_method", %{param: "value"})

      assert request.jsonrpc == "2.0"
      assert is_integer(request.id)
      assert request.id > 0
      assert request.method == "test_method"
      assert request.params == %{param: "value"}
    end

    test "creates valid JSON-RPC request with method only" do
      request = DeribitRpc.build_request("test_method")

      assert request.jsonrpc == "2.0"
      assert is_integer(request.id)
      assert request.method == "test_method"
      assert request.params == %{}
    end

    test "generates unique IDs for each request" do
      requests = for _ <- 1..100, do: DeribitRpc.build_request("test")
      ids = Enum.map(requests, & &1.id)

      assert length(Enum.uniq(ids)) == 100
    end
  end

  describe "auth_request/2" do
    test "creates auth request with client credentials" do
      request = DeribitRpc.auth_request("test_id", "test_secret")

      assert request.method == "public/auth"
      assert request.params.grant_type == "client_credentials"
      assert request.params.client_id == "test_id"
      assert request.params.client_secret == "test_secret"
    end
  end

  describe "set_heartbeat/1" do
    test "creates heartbeat request with default interval" do
      request = DeribitRpc.set_heartbeat()

      assert request.method == "public/set_heartbeat"
      assert request.params.interval == 30
    end

    test "creates heartbeat request with custom interval" do
      request = DeribitRpc.set_heartbeat(60)

      assert request.method == "public/set_heartbeat"
      assert request.params.interval == 60
    end
  end

  describe "test_request/0" do
    test "creates test request" do
      request = DeribitRpc.test_request()

      assert request.method == "public/test"
      assert request.params == %{}
    end
  end

  describe "subscribe/1" do
    test "creates subscribe request with channels" do
      channels = ["book.BTC-PERPETUAL.raw", "ticker.ETH-PERPETUAL.raw"]
      request = DeribitRpc.subscribe(channels)

      assert request.method == "public/subscribe"
      assert request.params.channels == channels
    end
  end

  describe "unsubscribe/1" do
    test "creates unsubscribe request with channels" do
      channels = ["book.BTC-PERPETUAL.raw"]
      request = DeribitRpc.unsubscribe(channels)

      assert request.method == "public/unsubscribe"
      assert request.params.channels == channels
    end
  end

  describe "market data methods" do
    test "get_instruments/1 creates request with currency" do
      request = DeribitRpc.get_instruments("BTC")

      assert request.method == "public/get_instruments"
      assert request.params.currency == "BTC"
    end

    test "get_order_book/2 creates request with default depth" do
      request = DeribitRpc.get_order_book("BTC-PERPETUAL")

      assert request.method == "public/get_order_book"
      assert request.params.instrument_name == "BTC-PERPETUAL"
      assert request.params.depth == 10
    end

    test "get_order_book/2 creates request with custom depth" do
      request = DeribitRpc.get_order_book("BTC-PERPETUAL", 20)

      assert request.method == "public/get_order_book"
      assert request.params.instrument_name == "BTC-PERPETUAL"
      assert request.params.depth == 20
    end

    test "ticker/1 creates request with instrument" do
      request = DeribitRpc.ticker("ETH-PERPETUAL")

      assert request.method == "public/ticker"
      assert request.params.instrument_name == "ETH-PERPETUAL"
    end
  end

  describe "trading methods" do
    test "buy/3 creates request with basic params" do
      request = DeribitRpc.buy("BTC-PERPETUAL", 100)

      assert request.method == "private/buy"
      assert request.params.instrument_name == "BTC-PERPETUAL"
      assert request.params.amount == 100
    end

    test "buy/3 creates request with additional options" do
      opts = %{type: "limit", price: 50_000}
      request = DeribitRpc.buy("BTC-PERPETUAL", 100, opts)

      assert request.method == "private/buy"
      assert request.params.instrument_name == "BTC-PERPETUAL"
      assert request.params.amount == 100
      assert request.params.type == "limit"
      assert request.params.price == 50_000
    end

    test "sell/3 creates request with basic params" do
      request = DeribitRpc.sell("ETH-PERPETUAL", 50)

      assert request.method == "private/sell"
      assert request.params.instrument_name == "ETH-PERPETUAL"
      assert request.params.amount == 50
    end

    test "sell/3 creates request with additional options" do
      opts = %{type: "market", reduce_only: true}
      request = DeribitRpc.sell("ETH-PERPETUAL", 50, opts)

      assert request.method == "private/sell"
      assert request.params.instrument_name == "ETH-PERPETUAL"
      assert request.params.amount == 50
      assert request.params.type == "market"
      assert request.params.reduce_only == true
    end

    test "cancel/1 creates request with order ID" do
      request = DeribitRpc.cancel("ETH-123456")

      assert request.method == "private/cancel"
      assert request.params.order_id == "ETH-123456"
    end

    test "get_open_orders/1 creates request with default params" do
      request = DeribitRpc.get_open_orders()

      assert request.method == "private/get_open_orders"
      assert request.params == %{}
    end

    test "get_open_orders/1 creates request with options" do
      opts = %{currency: "BTC", kind: "future"}
      request = DeribitRpc.get_open_orders(opts)

      assert request.method == "private/get_open_orders"
      assert request.params.currency == "BTC"
      assert request.params.kind == "future"
    end
  end
end
