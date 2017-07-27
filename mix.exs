defmodule MMQL.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :mmql,
     version: @version,
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :gproc],
     mod: {MMQL, []}]
  end

  defp deps do
    [
      {:gproc, "0.3.1"},
      {:nats, git: "https://github.com/nats-io/elixir-nats.git"},
      {:hulaaki, "~> 0.0.4"}
    ]
  end
end
