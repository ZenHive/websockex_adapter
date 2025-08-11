defmodule ZenWebsocket.Test.Support.MockWebSockHandler do
  @moduledoc """
  WebSock-based handler for the mock WebSocket server.

  This module implements the WebSock behavior to handle WebSocket connections
  in a standardized way, making testing more reliable.
  """

  @behaviour WebSock

  require Logger

  @impl WebSock
  def init(options) do
    parent = Keyword.get(options, :parent)
    log_event(:connection, :init, %{options: options}, %{})

    state = %{
      parent: parent,
      ref: make_ref()
    }

    # Register with parent server
    if parent do
      log_event(:connection, :registering_with_parent, %{parent: parent}, %{})
      send(parent, {:register_client, self(), state.ref})
    end

    {:ok, state}
  end

  @impl WebSock
  def handle_in({:text, message, opts}, state) do
    log_event(:message, :received_text_frame, %{message: message, opts: opts}, state)

    # Forward message to parent
    if state.parent do
      log_event(:message, :forwarding_text_to_parent, %{parent: state.parent}, state)
      send(state.parent, {:websocket_message, self(), :text, message})
    end

    # ECHO the text message back to the client automatically
    {:push, {:text, message}, state}
  end

  @impl WebSock
  # Additional handler to match the format actually being sent by WebSockAdapter
  def handle_in({text_message, [opcode: :text]}, state) when is_binary(text_message) do
    log_event(:message, :received_text_frame_alt, %{text_message: text_message}, state)

    # Forward message to parent if configured
    if state.parent do
      log_event(:message, :forwarding_text_to_parent, %{parent: state.parent}, state)
      send(state.parent, {:websocket_message, self(), :text, text_message})
    end

    # ECHO the text message back to the client automatically
    {:push, {:text, text_message}, state}
  end

  @impl WebSock
  def handle_in({:binary, message, opts}, state) do
    log_event(:message, :received_binary_frame, %{size: byte_size(message), opts: opts}, state)

    # Forward message to parent
    if state.parent do
      log_event(:message, :forwarding_binary_to_parent, %{parent: state.parent}, state)
      send(state.parent, {:websocket_message, self(), :binary, message})
    end

    # ECHO the binary message back to the client automatically
    {:push, {:binary, message}, state}
  end

  @impl WebSock
  # Additional handler for binary frames in the alternate format
  def handle_in({binary_message, [opcode: :binary]}, state) when is_binary(binary_message) do
    log_event(:message, :received_binary_frame_alt, %{size: byte_size(binary_message)}, state)

    # Forward message to parent if configured
    if state.parent do
      log_event(:message, :forwarding_binary_to_parent, %{parent: state.parent}, state)
      send(state.parent, {:websocket_message, self(), :binary, binary_message})
    end

    # ECHO the binary message back to the client automatically
    {:push, {:binary, binary_message}, state}
  end

  @impl WebSock
  def handle_in({:ping, message, _opts}, state) do
    Logger.debug("[MockWebSockHandler] Received ping frame with message: #{inspect(message)} from #{inspect(self())}")
    log_event(:message, :received_ping_frame, %{message: message}, state)
    # Auto-respond with pong
    Logger.debug("[MockWebSockHandler] Sending pong frame with message: #{inspect(message)} to #{inspect(self())}")
    {:push, {:pong, message}, state}
  end

  @impl WebSock
  def handle_in({:pong, message, _opts}, state) do
    Logger.debug("[MockWebSockHandler] Received pong frame with message: #{inspect(message)} from #{inspect(self())}")
    log_event(:message, :received_pong_frame, %{message: message}, state)
    # Ignore pongs
    {:ok, state}
  end

  @impl WebSock
  def handle_in({:close, code, reason, _opts}, state) do
    log_event(:message, :received_close_frame, %{code: code, reason: reason}, state)

    # Client requested close
    {:stop, :normal, state}
  end

  @impl WebSock
  def handle_info({:send_text, message}, state) do
    log_event(:message, :sending_text_frame, %{message: message}, state)
    # Send text frame to client
    {:push, {:text, message}, state}
  end

  @impl WebSock
  def handle_info({:send_binary, message}, state) do
    log_event(:message, :sending_binary_frame, %{size: byte_size(message)}, state)
    # Send binary frame to client
    {:push, {:binary, message}, state}
  end

  @impl WebSock
  def handle_info({:send_error, reason}, state) do
    # Log error and echo it back as text
    log_event(:error, :mock_websocket_error, %{reason: reason}, state)
    {:push, {:text, Jason.encode!(%{error: reason})}, state}
  end

  @impl WebSock
  def handle_info({:disconnect, code, reason}, state) do
    log_event(:connection, :disconnecting, %{code: code, reason: reason}, state)

    # Close the WebSocket connection
    {:push, {:close, code, reason}, state}
  end

  @impl WebSock
  def handle_info(message, state) do
    # Log unhandled messages
    log_event(:message, :received_unhandled_message, %{message: message}, state)
    {:ok, state}
  end

  @impl WebSock
  def terminate(reason, state) do
    # Log termination and notify parent if needed
    log_event(:connection, :terminating, %{reason: reason}, state)

    if state.parent && Process.alive?(state.parent) do
      log_event(:connection, :notifying_parent_termination, %{parent: state.parent}, state)
      send(state.parent, {:client_terminated, self(), reason})
    end

    :ok
  end

  # Logging helpers
  defp log_event(:connection, event, context, state) do
    if is_map(state) and Map.has_key?(state, :logging_handler) and
         function_exported?(state.logging_handler, :log_connection_event, 3) do
      state.logging_handler.log_connection_event(event, context, state)
    else
      Logger.info("[CONNECTION] #{inspect(event)} | #{inspect(context)}")
    end
  end

  defp log_event(:message, event, context, state) do
    if is_map(state) and Map.has_key?(state, :logging_handler) and
         function_exported?(state.logging_handler, :log_message_event, 3) do
      state.logging_handler.log_message_event(event, context, state)
    else
      Logger.debug("[MESSAGE] #{inspect(event)} | #{inspect(context)}")
    end
  end

  defp log_event(:error, event, context, state) do
    if is_map(state) and Map.has_key?(state, :logging_handler) and
         function_exported?(state.logging_handler, :log_error_event, 3) do
      state.logging_handler.log_error_event(event, context, state)
    else
      Logger.error("[ERROR] #{inspect(event)} | #{inspect(context)}")
    end
  end
end
