defmodule MMQL.Connection do
  require Logger
  use GenServer


  def start_link(options) do
    conn_name = "MMQL.Connection_" <> options.name
    Logger.debug  ">>> #{conn_name} start_link options = #{inspect options}"

    :gen_server.start_link(__MODULE__, options, [])
  end

  def init(options) do
    conn_name = "MMQL.Connection_" <> options.name
    proc_name = options.name
    Logger.debug  ">>> #{conn_name} init options=#{inspect options}"

    mq_cli_pid = case options.options.mq_type do
      :mqnats ->
        {:ok, mq_cli_pid} = MMQL.MQ.NATS.start_link(options.options)
        mq_cli_pid
      :mqmqtt ->
        {:ok, mq_cli_pid} = MMQL.MQ.MQTT.start_link(options)
        mq_cli_pid
      _else ->
        Logger.error  ">>> #{conn_name} error mq_type. connection down"
        throw("#{conn_name} error mq_type. connection down")
    end    

    Logger.debug  ">>> #{conn_name} init mq_cli_pid=#{inspect mq_cli_pid}"

    true = :gproc.add_local_name(proc_name)

    if options.options.autoconnect do
      send(self(), :autoconnect)
    end

    :gproc.reg(gproc_psub_key("event"))

    state = %{options: options, mq_cli_pid: mq_cli_pid}
    {:ok, state}
  end

  def handle_cast({:broadcast, message}, state) do
    conn_name = "MMQL.Connection_" <> state.options.name
    Logger.debug  ">>> #{conn_name} rcv broadcast message=#{inspect message}"
    {:noreply, state}
  end

  def handle_call(:connect, _from, state) do
    conn_name = "MMQL.Connection_" <> state.options.name
    Logger.debug  ">>> #{conn_name} handle_call :connect"

    reply = GenServer.call(state.mq_cli_pid, :connect)

    {:reply, reply, state}
  end

  def handle_call(:disconnect, _from, state) do
    conn_name = "MMQL.Connection_" <> state.options.name
    Logger.debug  ">>> #{conn_name} handle_call :disconnect"

    reply = GenServer.call(state.mq_cli_pid, :disconnect)

    {:reply, reply, state}
  end

  def handle_call({:subscribe, topic, subscriber_pid}, _from, state) do
    conn_name = "MMQL.Connection_" <> state.options.name
    Logger.debug  ">>> #{conn_name} handle_call :subscribe  topic=#{inspect topic} subscriber_pid=#{inspect subscriber_pid}"

    {:ok, subscriber_ref} = GenServer.call(state.mq_cli_pid, {:subscribe, topic})

    MMQL.HUB.reg_ref(subscriber_pid, subscriber_ref, state.options.name, topic)

    reply = %{reference: subscriber_ref}

    {:reply, reply, state}
  end

  def handle_call({:unsubscribe, topic}, _from, state) do
    conn_name = "MMQL.Connection_" <> state.options.name
    Logger.debug  ">>> #{conn_name} handle_call :unsubscribe  topic=#{inspect topic}"

    reply = GenServer.call(state.mq_cli_pid, {:unsubscribe, topic})

    {:reply, reply, state}
  end

  def handle_call({:publish, topic, message}, _from, state) do
    conn_name = "MMQL.Connection_" <> state.options.name
    Logger.debug  ">>> #{conn_name} handle_call :publish  topic=#{inspect topic} message=#{inspect message}"

    reply = GenServer.call(state.mq_cli_pid, {:publish, topic, message})

    {:reply, reply, state}
  end

  def handle_info(:autoconnect, state) do
    conn_name = "MMQL.Connection_" <> state.options.name
    Logger.debug  ">>> #{conn_name} handle_info :autoconnect"

    GenServer.call(state.mq_cli_pid, :connect)

    {:noreply, state}
  end


  defp gproc_psub_key(topic) do
    {:p, :l, topic}
  end

end
