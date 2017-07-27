defmodule MMQL do

  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Logger.debug "Application MMQL.start"

    children = [
      worker(MMQL.MQLog, []),
      worker(MMQL.ConnectionSup, []),
      worker(MMQL.HUB, [])
    ]

    opts = [strategy: :one_for_one, name: MMQL.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def connect(name) do
    GenServer.call({:via, :gproc, {:n, :l, name}}, :connect)
  end

  def disconnect(name) do
    GenServer.call({:via, :gproc, {:n, :l, name}}, :disconnect)
  end

  def sub(name, topic), do: subscribe(name, topic)
  def subscribe(name, topic) do
    subscriber_pid = self()
    GenServer.call({:via, :gproc, {:n, :l, name}}, {:subscribe, topic, subscriber_pid})
  end

  def usub(name, topic), do: unsubscribe(name, topic)
  def unsubscribe(name, topic) do
    GenServer.call({:via, :gproc, {:n, :l, name}}, {:unsubscribe, topic})
  end

  def pub(name, topic, message), do: publish(name, topic, message)
  def publish(name, topic, message) do
    GenServer.call({:via, :gproc, {:n, :l, name}}, {:publish, topic, message})
  end

end
