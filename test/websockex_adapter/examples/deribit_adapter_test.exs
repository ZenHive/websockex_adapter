defmodule WebsockexAdapter.Examples.DeribitAdapterTest do
  use ExUnit.Case, async: false

  alias WebsockexAdapter.Client
  alias WebsockexAdapter.Examples.DeribitAdapter

  require Logger

  @moduletag :integration

  describe "DeribitAdapter.connect/1" do
    test "connects to Deribit test API" do
      assert {:ok, adapter} = DeribitAdapter.connect()
      assert %DeribitAdapter{} = adapter
      assert adapter.authenticated == false
      assert MapSet.size(adapter.subscriptions) == 0

      # Clean up
      Client.close(adapter.client)
    end

    test "connects with custom URL" do
      custom_url = "wss://test.deribit.com/ws/api/v2"
      assert {:ok, adapter} = DeribitAdapter.connect(url: custom_url)
      assert adapter.client.url == custom_url

      # Clean up
      Client.close(adapter.client)
    end
  end

  describe "DeribitAdapter.authenticate/1" do
    test "returns error when no credentials provided" do
      {:ok, adapter} = DeribitAdapter.connect()

      assert {:error, :missing_credentials} = DeribitAdapter.authenticate(adapter)

      # Clean up
      Client.close(adapter.client)
    end

    @tag :skip_unless_env
    test "authenticates with valid credentials" do
      client_id = System.get_env("DERIBIT_CLIENT_ID")
      client_secret = System.get_env("DERIBIT_CLIENT_SECRET")

      if client_id && client_secret do
        {:ok, adapter} =
          DeribitAdapter.connect(client_id: client_id, client_secret: client_secret)

        # Wait for connection to be established
        :timer.sleep(1000)

        assert {:ok, authenticated_adapter} = DeribitAdapter.authenticate(adapter)
        assert authenticated_adapter.authenticated == true

        # Clean up
        Client.close(authenticated_adapter.client)
      else
        Logger.debug("Skipping authentication test - no credentials provided")
      end
    end
  end

  describe "DeribitAdapter.subscribe/2" do
    test "formats subscription messages correctly" do
      {:ok, adapter} = DeribitAdapter.connect()

      # Wait for connection
      :timer.sleep(1000)

      channels = ["deribit_price_index.btc_usd"]
      assert {:ok, subscribed_adapter} = DeribitAdapter.subscribe(adapter, channels)
      assert MapSet.member?(subscribed_adapter.subscriptions, "deribit_price_index.btc_usd")

      # Clean up
      Client.close(subscribed_adapter.client)
    end
  end

  describe "DeribitAdapter.unsubscribe/2" do
    test "removes channels from subscriptions" do
      {:ok, adapter} = DeribitAdapter.connect()

      # Wait for connection
      :timer.sleep(1000)

      channels = ["deribit_price_index.btc_usd", "deribit_price_index.eth_usd"]
      {:ok, subscribed} = DeribitAdapter.subscribe(adapter, channels)

      unsubscribe_channels = ["deribit_price_index.btc_usd"]
      assert {:ok, unsubscribed} = DeribitAdapter.unsubscribe(subscribed, unsubscribe_channels)

      refute MapSet.member?(unsubscribed.subscriptions, "deribit_price_index.btc_usd")
      assert MapSet.member?(unsubscribed.subscriptions, "deribit_price_index.eth_usd")

      # Clean up
      Client.close(unsubscribed.client)
    end
  end

  # Note: handle_message and create_message_handler were removed in the simplified adapter
  # Message handling is now done directly by the Client module

  @tag :integration
  @tag :skip_unless_env
  test "full integration with real Deribit API" do
    client_id = System.get_env("DERIBIT_CLIENT_ID")
    client_secret = System.get_env("DERIBIT_CLIENT_SECRET")

    if client_id && client_secret do
      # Connect to Deribit
      {:ok, adapter} = DeribitAdapter.connect(client_id: client_id, client_secret: client_secret)

      # Wait for connection
      :timer.sleep(2000)

      # Authenticate
      {:ok, authenticated} = DeribitAdapter.authenticate(adapter)

      # Subscribe to a channel
      {:ok, subscribed} = DeribitAdapter.subscribe(authenticated, ["deribit_price_index.btc_usd"])

      # Verify subscription
      assert MapSet.member?(subscribed.subscriptions, "deribit_price_index.btc_usd")

      # Wait for some messages
      :timer.sleep(5000)

      # Unsubscribe
      {:ok, unsubscribed} =
        DeribitAdapter.unsubscribe(subscribed, ["deribit_price_index.btc_usd"])

      # Verify unsubscription
      refute MapSet.member?(unsubscribed.subscriptions, "deribit_price_index.btc_usd")

      # Clean up
      Client.close(unsubscribed.client)
    else
      Logger.debug("Skipping full integration test - no credentials provided")

      Logger.debug("Set DERIBIT_CLIENT_ID and DERIBIT_CLIENT_SECRET environment variables to run this test")
    end
  end

  describe "DeribitAdapter.send_request/3" do
    test "sends generic request to public endpoint" do
      {:ok, adapter} = DeribitAdapter.connect()

      # Test with a public endpoint that doesn't require auth
      assert {:ok, response} = DeribitAdapter.send_request(adapter, "public/test", %{})
      assert response["result"]["version"]
      assert is_binary(response["result"]["version"])

      # Clean up
      Client.close(adapter.client)
    end

    test "sends request with parameters" do
      {:ok, adapter} = DeribitAdapter.connect()

      # Get instruments for BTC
      assert {:ok, response} =
               DeribitAdapter.send_request(adapter, "public/get_instruments", %{
                 currency: "BTC",
                 kind: "future"
               })

      assert response["result"]
      assert is_list(response["result"])

      # Clean up
      Client.close(adapter.client)
    end

    @tag :skip_unless_env
    test "sends authenticated request" do
      client_id = System.get_env("DERIBIT_CLIENT_ID")
      client_secret = System.get_env("DERIBIT_CLIENT_SECRET")

      if client_id && client_secret do
        {:ok, adapter} =
          DeribitAdapter.connect(
            client_id: client_id,
            client_secret: client_secret
          )

        # Authenticate first
        {:ok, adapter} = DeribitAdapter.authenticate(adapter)

        # Send authenticated request
        assert {:ok, response} =
                 DeribitAdapter.send_request(adapter, "private/get_account_summary", %{
                   currency: "BTC"
                 })

        assert response["result"]
        assert Map.has_key?(response["result"], "balance")
        assert Map.has_key?(response["result"], "equity")

        # Clean up
        Client.close(adapter.client)
      else
        Logger.debug("Set DERIBIT_CLIENT_ID and DERIBIT_CLIENT_SECRET environment variables to run this test")
      end
    end
  end

  # Note: close/1 was removed in the simplified adapter
  # Use Client.close(adapter.client) directly instead
end
