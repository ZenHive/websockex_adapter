defmodule WebsockexAdapter.FrameTest do
  use ExUnit.Case

  alias WebsockexAdapter.Frame

  describe "encoding frames" do
    test "text/1 creates text frame" do
      frame = Frame.text("hello world")
      assert frame == {:text, "hello world"}
    end

    test "binary/1 creates binary frame" do
      data = <<1, 2, 3, 4>>
      frame = Frame.binary(data)
      assert frame == {:binary, data}
    end

    test "ping/0 creates ping frame" do
      frame = Frame.ping()
      assert frame == {:ping, <<>>}
    end

    test "pong/1 creates pong frame with payload" do
      frame = Frame.pong("ping-data")
      assert frame == {:pong, "ping-data"}
    end

    test "pong/0 creates pong frame without payload" do
      frame = Frame.pong()
      assert frame == {:pong, <<>>}
    end
  end

  describe "decoding frames" do
    test "decode/1 handles text frames" do
      {:ok, frame} = Frame.decode({:ws, :text, "hello"})
      assert frame == {:text, "hello"}
    end

    test "decode/1 handles binary frames" do
      data = <<1, 2, 3>>
      {:ok, frame} = Frame.decode({:ws, :binary, data})
      assert frame == {:binary, data}
    end

    test "decode/1 handles ping frames" do
      {:ok, frame} = Frame.decode({:ws, :ping, "ping-data"})
      assert frame == {:ping, "ping-data"}
    end

    test "decode/1 handles pong frames" do
      {:ok, frame} = Frame.decode({:ws, :pong, "pong-data"})
      assert frame == {:pong, "pong-data"}
    end

    test "decode/1 handles close frames" do
      {:ok, frame} = Frame.decode({:ws, :close, <<1000::16>>})
      assert frame == {:close, <<>>}
    end

    test "decode/1 handles unknown frames gracefully" do
      {:error, message} = Frame.decode({:unknown, :frame})
      assert message =~ "Unknown frame type"
    end
  end
end
