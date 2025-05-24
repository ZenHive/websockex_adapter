defmodule WebsockexAdapter.Test.Support.GunMonitor do
  @moduledoc """
  A simple monitor for Gun processes that intercepts and forwards messages.

  This module helps debug Gun message flow in integration tests by acting as
  a middleman to track and forward messages between Gun and client processes.
  """

  use GenServer

  require Logger

  def start_link(target_pid) do
    GenServer.start_link(__MODULE__, target_pid)
  end

  def init(target_pid) do
    Logger.debug("GunMonitor started for target process")
    {:ok, %{target: target_pid, messages: []}}
  end

  def monitor_gun(gun_pid, monitor_pid) do
    Logger.debug("Setting GunMonitor as owner for Gun process")
    :ok = :gun.set_owner(gun_pid, monitor_pid)
  end

  def handle_info({:gun_up, gun_pid, protocol} = msg, %{target: target} = state) do
    Logger.info("Gun connection established: protocol=#{inspect(protocol)}")
    send(target, msg)
    {:noreply, %{state | messages: [{:gun_up, gun_pid, protocol} | state.messages]}}
  end

  def handle_info({:gun_down, _, _, reason, _, _} = msg, %{target: target} = state) do
    Logger.warning("Gun connection down: reason=#{inspect(reason)}")
    send(target, msg)
    {:noreply, %{state | messages: [msg | state.messages]}}
  end

  def handle_info({:gun_upgrade, _, _, ["websocket"], _} = msg, %{target: target} = state) do
    Logger.info("WebSocket upgrade successful")
    send(target, msg)
    {:noreply, %{state | messages: [msg | state.messages]}}
  end

  def handle_info({:gun_ws, _, _, _} = msg, %{target: target} = state) do
    Logger.debug("WebSocket frame received")
    send(target, msg)
    {:noreply, %{state | messages: [msg | state.messages]}}
  end

  def handle_info({:gun_error, _, _, reason} = msg, %{target: target} = state) do
    Logger.warning("Gun error: #{inspect(reason)}")
    send(target, msg)
    {:noreply, %{state | messages: [msg | state.messages]}}
  end

  def handle_info({:gun_response, _, _, _, status, _} = msg, %{target: target} = state) do
    Logger.info("HTTP response: status=#{status}")
    send(target, msg)
    {:noreply, %{state | messages: [msg | state.messages]}}
  end

  def handle_info({:gun_data, _, _, _, _} = msg, %{target: target} = state) do
    Logger.debug("HTTP data received")
    send(target, msg)
    {:noreply, %{state | messages: [msg | state.messages]}}
  end

  def handle_info(other_msg, %{target: target} = state) do
    Logger.debug("Other Gun message: #{inspect(other_msg)}")
    send(target, other_msg)
    {:noreply, %{state | messages: [other_msg | state.messages]}}
  end

  def get_messages(pid) do
    GenServer.call(pid, :get_messages)
  end

  def handle_call(:get_messages, _from, state) do
    {:reply, Enum.reverse(state.messages), state}
  end
end
