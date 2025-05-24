# Create a plug router for handling HTTP and WebSocket requests
defmodule WebsockexAdapter.Test.Support.MockWebSockServer.Router do
  use Plug.Router

  import Plug.Conn, only: [assign: 3, send_resp: 3]

  require Logger

  # Initialize the plug with options passed from Plug.Cowboy
  def init(opts) do
    opts
  end

  # Plug to store the server_pid in connection assigns
  defp put_init_opts(conn, opts) do
    server_pid = Keyword.get(opts, :server_pid)
    assign(conn, :server_pid, server_pid)
  end

  # Run this plug first to get the opts
  plug(:put_init_opts)
  plug(:match)
  plug(:dispatch)

  get "/ws" do
    Logger.debug("Router received WebSocket upgrade request")

    # Fetch parent PID from assigns (put there by :put_init_opts plug)
    server_pid = conn.assigns[:server_pid]

    if !server_pid do
      Logger.error("MockWebSockServer parent PID not found in assigns!")
    end

    conn =
      WebSockAdapter.upgrade(
        conn,
        WebsockexAdapter.Test.Support.MockWebSockHandler,
        # Pass runtime PID
        [parent: server_pid],
        []
      )

    # WebSockAdapter will take over the connection from here
    conn
  end

  match _ do
    Logger.debug("Router received non-WebSocket request: #{conn.request_path}")
    send_resp(conn, 404, "Not Found")
  end
end
