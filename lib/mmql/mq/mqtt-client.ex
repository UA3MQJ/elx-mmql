defmodule MMQL.MQ.MQTT.Client do
  @moduledoc """
  Module-wrapper client for connecting with MQ NATS
  """

  use Hulaaki.Client

  @doc """
  Send rcvd message to MMQL.MQ.MQTT
  """
  def on_subscribed_publish(options) do
    send(options[:state].mqtt_pid, {:msg, options[:message]})
  end

end
