defmodule ZenWebsocket.Examples.Docs.BasicUsage do
  @moduledoc """
  Basic usage examples from the documentation.
  These examples demonstrate simple WebSocket connections and message handling.
  """

  alias ZenWebsocket.Client
  alias ZenWebsocket.Config

  @doc """
  Simple echo server connection example.

  Connects to an echo WebSocket server, sends a message, and receives the echo.
  The default handler automatically sends messages to the calling process.
  """
  def echo_server_example do
    # Connect to an echo WebSocket server
    {:ok, client} = Client.connect("wss://echo.websocket.org")

    # Send a message
    :ok = Client.send_message(client, "Hello, WebSocket!")

    # Close the connection
    :ok = Client.close(client)

    {:ok, client}
  end

  @doc """
  Connection with custom headers example.

  Shows how to connect with authorization headers and other custom headers.
  """
  def custom_headers_example(token) do
    config = %Config{
      url: "wss://echo.websocket.org",
      headers: [
        {"Authorization", "Bearer #{token}"},
        {"X-API-Version", "2.0"}
      ],
      timeout: 10_000
    }

    {:ok, client} = Client.connect(config)
    {:ok, client}
  end
end
