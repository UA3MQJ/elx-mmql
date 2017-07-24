defmodule Mmql.Mixfile do
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
    [applications: [:logger]]
  end

  defp deps do
    [
      {:mqnats, git: "https://github.com/UA3MQJ/elx-mq-nats.git"},
      {:natural_sort, git: "https://github.com/DanCouper/natural_sort.git"}
    ]
  end
end
