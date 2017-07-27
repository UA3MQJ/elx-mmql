use Mix.Config

config :mmql,
  options: %{
    connections: %{
      "A" => %{
        mq_type: :mqnats,
        autoconnect: false,
        host: "demo.nats.io",
        port: 4222,
        timeout: 6000
      },

      "B" => %{
        mq_type: :mqnats,
        autoconnect: false,
        host: "127.0.0.1",
        port: 4222,
        timeout: 6000
      },

      "C" => %{
        mq_type: :mqmqtt,
        autoconnect: false,
        host: "test.mosquitto.org",
        port: 1883
        # host: "127.0.0.1",
        # port: 1883
      }
    }
  }
