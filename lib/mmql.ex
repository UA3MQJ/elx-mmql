defmodule Mmql do
  @moduledoc """
  MQ lib
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    mq_type = Application.get_env(:mmql, :mq_type, :error)

    children = case mq_type do
      :nats ->
        [worker(Mmql.Mqs.Nats, [nats_config()])]
      :error ->
        raise("mq type not set in config")
      err_mq_type ->
        raise("mq type #{inspect err_mq_type} not supported")
    end

    opts = [strategy: :one_for_one, name: Mmql.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def send_text(text) do
    Mmql.Mqs.Nats.send_text(text)
  end

  # NATS
  defp nats_config() do
    config = Application.get_env(:mmql, :nats, %{})

    unless is_bitstring(config.host) do
      raise({:bad_host, config.host})
    end

    unless is_bitstring(config.subject) do
      raise({:bad_subject, config.subject})
    end

    unless is_integer(config.port) do
      raise({:bad_port, config.port})
    end

    config
  end

end
