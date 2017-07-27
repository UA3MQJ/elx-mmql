defmodule MMQL.MQ.MQTT do
   
  use GenServer
  require Logger

  def start_link(options) do
    Logger.debug  ">>> MMQL.MQ.MQTT start_link options = #{inspect options}"

    GenServer.start_link(__MODULE__, [options])
  end

  def connect(pid) do
    Logger.debug  ">>> MMQL.MQ.MQTT connect pid = #{inspect pid}"
    GenServer.call(pid, :connect)
  end

  def init([options]) do
    Logger.debug  ">>> MMQL.MQ.MQTT init options = #{inspect options}"

    state = %{
      options: options,
      mqtt_pid: nil,
      mqtt_status: :disconnected,
      sub_autoincrement: 1
    }

    {:ok, state}
  end

  def handle_call(:connect, _from, %{:mqtt_status => :connected} = state) do
    {:reply, {:error, :already_connected}, state}
  end
  def handle_call(:connect, _from, state) do
    Logger.debug  ">>> MMQL.MQ.MQTT handle_call connect"

    mqtt_config = [
      client_id: state.options.name,
      host: state.options.options.host,
      port: state.options.options.port      
    ]

    Logger.debug  ">>> MMQL.MQ.MQTT mqtt_config = #{inspect mqtt_config}"

    {:ok, mqtt_pid} = MMQL.MQ.MQTT.Client.start_link(%{mqtt_pid: self()})

    response = MMQL.MQ.MQTT.Client.connect(mqtt_pid, mqtt_config)

    {:reply, response, %{state | mqtt_pid: mqtt_pid, mqtt_status: :connected}}
  end

  def handle_call(:disconnect, _from, %{:mqtt_status => :disconnected} = state) do
    {:reply, {:error, :not_connected}, state}
  end
  def handle_call(:disconnect, _from, state) do
    Logger.debug  ">>> MMQL.MQ.MQTT handle_call disconnect"

    :ok = MMQL.MQ.MQTT.Client.stop(state.mqtt_pid)

    {:reply, :ok, %{state| mqtt_pid: nil, mqtt_status: :disconnected}}
  end

  def handle_call({:subscribe, _topic, _pid}, _from, %{:mqtt_status => :disconnected} = state) do
    {:reply, {:error, :not_connected}, state}
  end
  def handle_call({:subscribe, topic}, _from, state) do
    Logger.debug  ">>> MMQL.MQ.MQTT handle_call subscribe"

    sub_options = [id: state.sub_autoincrement, topics: [topic], qoses: [0]]
    :ok = MMQL.MQ.MQTT.Client.subscribe(state.mqtt_pid, sub_options)

    {:reply, {:ok, _ref = state.options.name}, %{state | sub_autoincrement: state.sub_autoincrement + 1}}
  end

  def handle_call({:unsubscribe, _topic}, _from, %{:mqtt_status => :disconnected} = state) do
    {:reply, {:error, :not_connected}, state}
  end
  def handle_call({:unsubscribe, topic}, _from, state) do
    Logger.debug  ">>> MMQL.MQ.MQTT handle_call unsubscribe"
    usub_options = [id: state.sub_autoincrement, topics: [topic]]
    :ok = MMQL.MQ.MQTT.Client.unsubscribe(state.mqtt_pid, usub_options)

    {:reply, :ok, %{state | sub_autoincrement: state.sub_autoincrement + 1}}
  end

  def handle_call({:publish, _topic, _message}, _from, %{:mqtt_status => :disconnected} = state) do
    {:reply, {:error, :not_connected}, state}
  end
  def handle_call({:publish, topic, message}, _from, state) do
    Logger.debug  ">>> MMQL.MQ.MQTT handle_call publish topic = #{inspect topic} message = #{inspect message}"

    pub_options = [id: state.sub_autoincrement, topic: topic, message: message,
                   dup: 0, qos: 0, retain: 0]
    reply = MMQL.MQ.MQTT.Client.publish(state.mqtt_pid, pub_options)
    Logger.debug  ">>> MMQL.MQ.MQTT handle_call publish reply = #{inspect reply}"

    {:reply, :ok, %{state | sub_autoincrement: state.sub_autoincrement + 1}}
  end

  # receive sub
  def handle_info({:msg, message} = msg, state) do
    Logger.debug  ">>> MMQL.MQ.MQTT handle_info :msg msg=#{inspect msg}"
    
    MMQL.HUB.rcv_from_ref(_ref = state.options.name, message.topic, message.message)

    {:noreply, state}
  end
end
