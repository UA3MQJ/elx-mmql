defmodule MMQL do

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
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
    GenServer.call({:via, :gproc, {:n, :l, name}}, {:subscribe, topic, self()})
  end

  def usub(name, topic), do: unsubscribe(name, topic)
  def unsubscribe(name, topic) do
    GenServer.call({:via, :gproc, {:n, :l, name}}, {:unsubscribe, topic, self()})
  end

  def pub(name, topic, message), do: publish(name, topic, message)
  def publish(name, topic, message) do
    GenServer.call({:via, :gproc, {:n, :l, name}}, {:publish, topic, message})
  end

end
