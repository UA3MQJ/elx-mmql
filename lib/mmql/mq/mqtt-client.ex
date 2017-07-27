defmodule MMQL.MQ.MQTT.Client do
  
  use Hulaaki.Client

  def on_subscribed_publish(options) do
    send(options[:state].mqtt_pid, {:msg, options[:message]})
  end

end
