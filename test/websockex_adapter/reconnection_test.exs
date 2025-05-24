defmodule WebsockexAdapter.ReconnectionTest do
  use ExUnit.Case

  alias WebsockexAdapter.Reconnection

  describe "calculate_backoff/3" do
    test "returns base delay for first attempt" do
      assert Reconnection.calculate_backoff(0, 1000) == 1000
      assert Reconnection.calculate_backoff(0, 1000, 5000) == 1000
    end

    test "doubles delay for each attempt" do
      assert Reconnection.calculate_backoff(1, 1000) == 2000
      assert Reconnection.calculate_backoff(2, 1000) == 4000
      assert Reconnection.calculate_backoff(3, 1000) == 8000
    end

    test "caps delay at default 30 seconds" do
      assert Reconnection.calculate_backoff(10, 1000) == 30_000
      assert Reconnection.calculate_backoff(20, 1000) == 30_000
    end

    test "caps delay at custom max_backoff" do
      assert Reconnection.calculate_backoff(10, 1000, 5000) == 5000
      assert Reconnection.calculate_backoff(20, 1000, 10_000) == 10_000
    end
  end

  describe "max_retries_exceeded?/2" do
    test "returns false when under limit" do
      refute Reconnection.max_retries_exceeded?(0, 3)
      refute Reconnection.max_retries_exceeded?(2, 3)
    end

    test "returns true when at or over limit" do
      assert Reconnection.max_retries_exceeded?(3, 3)
      assert Reconnection.max_retries_exceeded?(4, 3)
    end
  end

  describe "should_reconnect?/1" do
    test "returns true for recoverable errors" do
      assert Reconnection.should_reconnect?(:timeout)
      assert Reconnection.should_reconnect?(:connection_failed)
    end

    test "returns false for non-recoverable errors" do
      refute Reconnection.should_reconnect?(:invalid_credentials)
      refute Reconnection.should_reconnect?(:protocol_error)
    end
  end
end
