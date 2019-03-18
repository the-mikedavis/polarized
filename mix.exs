defmodule Polarized.MixProject do
  use Mix.Project

  def project do
    [
      app: :polarized,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        bless: :test,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        credo: :test,
        "test.watch": :test,
        dialyzer: :test,
        build: :prod,
        goose: :prod
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        plt_add_apps: [:mnesia, :ex_unit]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Polarized.Application, []},
      included_applications: [:mnesia],
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto, "~> 3.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:poison, "~> 3.0"},
      {:plug_cowboy, "~> 2.0"},

      # Slime HTML
      {:phoenix_slime, "~> 0.10"},

      # encrypting passwords
      {:comeonin, "~> 4.1"},
      {:argon2_elixir, "~> 1.3"},

      # twitter
      {:oauther, "~> 1.1"},
      {:extwitter, github: "the-mikedavis/extwitter", branch: "behaviour"},

      # quantum jobs for refresh
      {:quantum, "~> 2.3"},

      # test
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.7", only: :test},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:private, "~> 0.1.1"},
      {:mox, "~> 0.5"},

      # release
      {:distillery, "~> 2.0", runtime: false},
      {:duckduck, "~> 1.1"}
    ]
  end

  defp aliases do
    [
      bless: [&bless/1],
      build: [&build/1]
    ]
  end

  defp bless(_) do
    [
      {"compile", ["--warnings-as-errors", "--force"]},
      {"coveralls.html", []},
      {"format", ["--check-formatted"]},
      {"credo", []},
      {"dialyzer", []}
    ]
    |> Enum.each(fn {task, args} ->
      [:cyan, "Running #{task} with args #{inspect(args)}"]
      |> IO.ANSI.format()
      |> IO.puts()

      Mix.Task.run(task, args)
    end)
  end

  defp build(_) do
    assets = Path.join(File.cwd!(), "assets")

    [:cyan, "Building assets with webpack"]
    |> IO.ANSI.format()
    |> IO.puts()

    [assets, "node_modules", ".bin", "webpack"]
    |> Path.join()
    |> System.cmd(["--production"], cd: assets)

    [
      {"phx.digest", []},
      {"release", ["--env=prod"]},
      {"goose", []}
    ]
    |> Enum.each(fn {task, args} ->
      [:cyan, "Running #{task} with args #{inspect(args)}"]
      |> IO.ANSI.format()
      |> IO.puts()

      Mix.Task.run(task, args)
    end)
  end
end
