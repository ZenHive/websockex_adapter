defmodule Mix.Tasks.StabilityTest do
  @shortdoc "Run ZenWebsocket stability tests"

  @moduledoc """
  Runs stability tests for ZenWebsocket with Deribit integration.

  ## Usage

  Run 1-hour development stability test:
      mix stability_test
      
  Run 24-hour production stability test:
      mix stability_test --full
      
  Run with custom duration (in hours):
      mix stability_test --hours 6
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    # Start the application
    Application.ensure_all_started(:zen_websocket)

    # Parse arguments
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [full: :boolean, hours: :integer],
        aliases: [f: :full, h: :hours]
      )

    # Check for credentials
    if !(System.get_env("DERIBIT_CLIENT_ID") && System.get_env("DERIBIT_CLIENT_SECRET")) do
      IO.puts(:stderr, """

      ❌ Missing Deribit credentials!

      Please set the following environment variables:
        export DERIBIT_CLIENT_ID="your_client_id"
        export DERIBIT_CLIENT_SECRET="your_client_secret"
      """)

      System.halt(1)
    end

    # Determine which test to run
    cond do
      opts[:full] ->
        IO.puts("🚀 Starting 24-hour stability test...")

        System.cmd("mix", ["test", "--only", "stability", "test/zen_websocket/examples/deribit_stability_test.exs"],
          into: IO.stream(:stdio, :line)
        )

      opts[:hours] ->
        hours = opts[:hours]
        IO.puts("🚀 Starting #{hours}-hour custom stability test...")
        # For now, we'll use the dev test with a notice
        IO.puts("⚠️  Custom duration not implemented yet. Running 1-hour test instead.")

        System.cmd(
          "mix",
          ["test", "--only", "stability_dev", "test/zen_websocket/examples/deribit_stability_dev_test.exs"],
          into: IO.stream(:stdio, :line)
        )

      true ->
        IO.puts("🚀 Starting 1-hour development stability test...")

        System.cmd(
          "mix",
          ["test", "--only", "stability_dev", "test/zen_websocket/examples/deribit_stability_dev_test.exs"],
          into: IO.stream(:stdio, :line)
        )
    end
  end
end
