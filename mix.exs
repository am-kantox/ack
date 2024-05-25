defmodule Ack.MixProject do
  use Mix.Project

  @app :ack
  @version "0.4.0"

  def project do
    [
      app: @app,
      name: "Ack",
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      package: package(),
      xref: [exclude: []],
      description: description(),
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      dialyzer: [
        plt_file: {:no_warn, ".dialyzer/dialyzer.plt"},
        plt_add_deps: :app_tree,
        plt_add_apps: [:mix],
        list_unused_filters: true,
        ignore_warnings: ".dialyzer/ignore.exs"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :camarero],
      mod: {Ack.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:camarero, "~> 1.0"},
      {:credo, "~> 1.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 1.0", only: :dev}
    ]
  end

  defp description do
    """
    Tiny drop-in for painless acknowledgements across different applications.
    """
  end

  defp package do
    [
      name: @app,
      files: ~w|config lib mix.exs README.md|,
      maintainers: ["Aleksei Matiushkin"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/am-kantox/#{@app}",
        "Docs" => "https://hexdocs.pm/#{@app}"
      }
    ]
  end

  defp aliases do
    [
      test: ["test --exclude distributed", "test --exclude test include distributed"],
      quality: ["format", "credo --strict", "dialyzer --unmatched_returns"],
      "quality.ci": [
        "format --check-formatted",
        "credo --strict",
        "dialyzer"
      ]
    ]
  end

  defp docs do
    [
      main: "how_to_ack",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/#{@app}",
      logo: "stuff/i/logo-48.png",
      source_url: "https://github.com/am-kantox/#{@app}",
      extras: [
        "stuff/how_to_ack.md",
        "stuff/plugging_it_in.md"
      ]
    ]
  end
end
