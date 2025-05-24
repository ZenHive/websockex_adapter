defmodule WebsockexAdapter.ClientSupervisorTest do
  use ExUnit.Case, async: true

  alias WebsockexAdapter.Client
  alias WebsockexAdapter.ClientSupervisor

  @deribit_test_url "wss://test.deribit.com/ws/api/v2"

  setup do
    # Start the supervisor for tests
    {:ok, sup_pid} = start_supervised(ClientSupervisor)
    {:ok, supervisor: sup_pid}
  end

  describe "start_client/2" do
    test "starts a supervised client connection" do
      {:ok, client} = ClientSupervisor.start_client(@deribit_test_url)

      assert %Client{state: :connected, server_pid: pid} = client
      assert is_pid(pid)
      assert Process.alive?(pid)

      # Verify we can send messages
      assert :ok = Client.send_message(client, Jason.encode!(%{test: "message"}))

      # Clean up
      Client.close(client)
    end

    test "returns error for invalid URL" do
      assert {:error, _} = ClientSupervisor.start_client("invalid-url")
    end

    test "supervised client restarts on crash" do
      {:ok, client} = ClientSupervisor.start_client(@deribit_test_url)
      original_pid = client.server_pid

      # Force a crash
      Process.exit(original_pid, :kill)

      # Give supervisor time to restart
      Process.sleep(100)

      # Check that a new process was started
      clients = ClientSupervisor.list_clients()
      assert length(clients) == 1
      [new_pid] = clients

      assert new_pid != original_pid
      assert Process.alive?(new_pid)
    end
  end

  describe "list_clients/0" do
    test "lists all active supervised clients" do
      assert ClientSupervisor.list_clients() == []

      {:ok, client1} = ClientSupervisor.start_client(@deribit_test_url)
      {:ok, client2} = ClientSupervisor.start_client(@deribit_test_url)

      clients = ClientSupervisor.list_clients()
      assert length(clients) == 2
      assert client1.server_pid in clients
      assert client2.server_pid in clients

      # Clean up
      Client.close(client1)
      Client.close(client2)
    end
  end

  describe "stop_client/1" do
    test "gracefully stops a supervised client" do
      {:ok, client} = ClientSupervisor.start_client(@deribit_test_url)

      assert :ok = ClientSupervisor.stop_client(client.server_pid)
      refute Process.alive?(client.server_pid)

      # Verify it's removed from the supervisor
      assert ClientSupervisor.list_clients() == []
    end
  end
end
