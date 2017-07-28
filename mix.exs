defmodule MMQL.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :mmql,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [applications: [:logger, :gproc],
     mod: {MMQL, []}]
  end

  defp deps do
    [
      {:gproc, "0.3.1"},
      {:nats, git: "https://github.com/nats-io/elixir-nats.git"},
      {:hulaaki, "~> 0.0.4"},

      {:inch_ex, "~> 0.5.3", only: :docs},
      {:earmark, "~> 0.2.1", only: [:dev, :docs]},
      {:ex_doc, "~> 0.12", only: [:dev, :docs]},
      {:dialyze, "~> 0.2.1", only: :test},
      {:excoveralls, "~> 0.5.4", only: [:dev, :test]}
    ]
  end
end
