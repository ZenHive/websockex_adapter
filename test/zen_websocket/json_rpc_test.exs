defmodule ZenWebsocket.JsonRpcTest do
  use ExUnit.Case

  alias ZenWebsocket.JsonRpc

  describe "build_request/2" do
    test "builds request with method and params" do
      {:ok, request} = JsonRpc.build_request("public/auth", %{grant_type: "client_credentials"})

      assert request["jsonrpc"] == "2.0"
      assert request["method"] == "public/auth"
      assert request["params"] == %{grant_type: "client_credentials"}
      assert is_integer(request["id"])
      assert request["id"] > 0
    end

    test "builds request with method only" do
      {:ok, request} = JsonRpc.build_request("public/test")

      assert request["jsonrpc"] == "2.0"
      assert request["method"] == "public/test"
      refute Map.has_key?(request, "params")
      assert is_integer(request["id"])
    end

    test "generates unique IDs" do
      {:ok, req1} = JsonRpc.build_request("method1")
      {:ok, req2} = JsonRpc.build_request("method2")

      assert req1["id"] != req2["id"]
    end
  end

  describe "match_response/1" do
    test "matches successful result" do
      response = %{"jsonrpc" => "2.0", "id" => 123, "result" => %{"token" => "abc123"}}
      assert {:ok, %{"token" => "abc123"}} = JsonRpc.match_response(response)
    end

    test "matches error response" do
      response = %{
        "jsonrpc" => "2.0",
        "id" => 123,
        "error" => %{"code" => -32_600, "message" => "Invalid request"}
      }

      assert {:error, {-32_600, "Invalid request"}} = JsonRpc.match_response(response)
    end

    test "matches notification" do
      response = %{
        "jsonrpc" => "2.0",
        "method" => "heartbeat",
        "params" => %{"type" => "test_request"}
      }

      assert {:notification, "heartbeat", %{"type" => "test_request"}} = JsonRpc.match_response(response)
    end
  end

  describe "defrpc macro" do
    defmodule TestApi do
      @moduledoc false
      use ZenWebsocket.JsonRpc

      defrpc(:authenticate, "public/auth")
      defrpc(:subscribe, "public/subscribe", doc: "Subscribe to market data channels")
    end

    test "generates function that builds request" do
      {:ok, request} = TestApi.authenticate(%{grant_type: "client_credentials"})

      assert request["method"] == "public/auth"
      assert request["params"] == %{grant_type: "client_credentials"}
    end

    test "generated function works without params" do
      {:ok, request} = TestApi.authenticate()

      assert request["method"] == "public/auth"
      assert request["params"] == %{}
    end
  end
end
