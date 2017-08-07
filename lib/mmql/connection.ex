defmodule MMQL.Connection do
  
  use GenServer
  require Logger

  def start_link(options) do
    :gen_server.start_link(__MODULE__, options, [])
  end

  def init(options) do
    conn_name = "MMQL.Connection_" <> options.name
    proc_name = options.name

    mq_cli_pid = case options.options.mq_type do
      :mqnats ->
        {:ok, mq_cli_pid} = MMQL.MQ.NATS.start_link(options.options)
        mq_cli_pid
      :mqmqtt ->
        {:ok, mq_cli_pid} = MMQL.MQ.MQTT.start_link(options)
        mq_cli_pid
      _else ->
        Logger.error ">>> #{conn_name} error mq_type. connection down"
        throw("#{conn_name} error mq_type. connection down")
    end    

    true = :gproc.add_local_name(proc_name)

    if options.options.autoconnect do
      send(self(), :autoconnect)
    end

    state = %{options: options, mq_cli_pid: mq_cli_pid}
    {:ok, state}
  end

  def handle_call(:connect, _from, state) do
    reply = GenServer.call(state.mq_cli_pid, :connect)
    {:reply, reply, state}
  end

  def handle_call(:disconnect, _from, state) do
    reply = GenServer.call(state.mq_cli_pid, :disconnect)
    {:reply, reply, state}
  end

  def handle_call({:subscribe, topic, s_pid}, _from, state) do
    {:ok, subscriber_ref} = GenServer.call(state.mq_cli_pid, {:subscribe, topic, s_pid})

    MMQL.HUB.reg_ref(s_pid, subscriber_ref, state.options.name, topic)

    reply = %{reference: subscriber_ref}

    {:reply, reply, state}
  end

  def handle_call({:unsubscribe, topic, s_pid}, _from, state) do
    MMQL.HUB.unreg_ref(s_pid, state.options.name, topic)
    reply = GenServer.call(state.mq_cli_pid, {:unsubscribe, topic, s_pid})
    {:reply, reply, state}
  end

  def handle_call({:publish, topic, message}, _from, state) do
    reply = GenServer.call(state.mq_cli_pid, {:publish, topic, message})
    {:reply, reply, state}
  end

  def handle_info(:autoconnect, state) do
    GenServer.call(state.mq_cli_pid, :connect)
    {:noreply, state}
  end

end
