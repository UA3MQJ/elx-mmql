defmodule MMQL.MQ.MQTT.Client do
   
  use Hulaaki.Client
  require Logger

  # def connect(pid) do
  #   Logger.debug  ">>> MMQL.MQ.MQTT connect pid = #{inspect pid}"
  #   GenServer.call(pid, :connect)
  # end

  # def handle_call(:connect, _from, %{:mqtt_status => :connected} = state) do
  #   {:reply, {:error, :already_connected}, state}
  # end
  # def handle_call(:connect, _from, state) do
  #   Logger.debug  ">>> MMQL.MQ.MQTT handle_call connect state = #{inspect state}"

  #   mqtt_config = [
  #     client_id: state.options.name,
  #     host: state.options.options.host,
  #     port: state.options.options.port
  #   ]

  #   Logger.debug  ">>> MMQL.MQ.MQTT mqtt_config = #{inspect mqtt_config}"

  #   response = __MODULE__.connect(state.mqtt_pid, mqtt_config)

  #   {:reply, response, state}
  # end

  def on_subscribed_publish(options) do
    Logger.debug  ">>> MMQL.MQ.MQTT.Client on_subscribed_publish options = #{inspect options}"
    send(options[:state].mqtt_pid, {:msg, options[:message]})
  end

end
