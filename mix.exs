defmodule WebsockexAdapter.MixProject do
  use Mix.Project

  @version "0.1.1"

  def project do
    [
      app: :websockex_adapter,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      dialyzer: dialyzer(),
      aliases: aliases(),
      preferred_cli_env: [
        dialyzer: :dev,
        credo: :dev,
        sobelow: :dev,
        lint: :dev,
        typecheck: :dev,
        security: :dev,
        coverage: :test,
        check: :dev,
        docs: :dev
      ],

      # Hex Package metadata
      description: description(),
      package: package(),

      # Docs
      name: "WebsockexAdapter",
      source_url: "https://github.com/ZenHive/websockex_adapter",
      homepage_url: "https://github.com/ZenHive/websockex_adapter",
      docs: [
        main: "WebsockexAdapter",
        extras: ["README.md"],
        source_url: "https://github.com/ZenHive/websockex_adapter",
        source_ref: "v#{@version}"
      ]
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gun, "~> 2.2"},
      {:jason, "~> 1.4"},

      # Static code analysis
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # Documentation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},

      # Tasks
      {:task_validator, "~> 0.6.0", only: [:dev, :test], runtime: false},

      # Mocks
      # {:mox, "~> 1.0", only: :test},

      # Security scanning
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},

      # Used for mock WebSocket server in tests
      {:cowboy, "~> 2.10", only: :test},

      # WebSock for standardized WebSocket handling
      {:websock, "~> 0.5", only: :test},
      {:websock_adapter, "~> 0.5", only: :test},

      # Required for Plug.Cowboy.http/3
      {:plug_cowboy, "~> 2.6", only: :test},
      {:stream_data, "~> 1.0", only: [:test, :dev]},
      {:styler, "~> 1.4", only: [:dev, :test], runtime: false},

      # For generating temporary files (certificates) in tests
      {:temp, "~> 0.4", only: :test},

      # For generating self-signed certificates in tests
      {:x509, "~> 0.8", only: :test},
      {:certifi, "~> 2.5"},
      {:telemetry, "~> 1.3"},
      # {:meck, "~> 0.9", only: :test},
      {:rename, "~> 0.1.0", only: :dev}

      # {:mint_web_socket, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end

  # Add aliases for code quality tools
  defp aliases do
    [
      lint: ["credo --strict"],
      typecheck: ["dialyzer"],
      security: ["sobelow --exit --config"],
      coverage: ["test --cover"],
      docs: ["docs"],
      check: [
        "lint",
        "typecheck",
        "security",
        "coverage"
      ],
      rebuild: ["deps.clean --all", "clean", "deps.get", "compile", "dialyzer", "credo --strict"]
    ]
  end

  defp description do
    """
    A robust WebSocket client library based on Websockex, extended with Gun transport,
    behavior-based architecture, automatic reconnection, and enterprise-grade features.
    """
  end

  defp package do
    [
      name: "websockex_adapter",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/ZenHive/websockex_adapter",
        "Docs" => "https://hexdocs.pm/websockex_adapter"
      },
      maintainers: ["ZenHive"]
    ]
  end
end
