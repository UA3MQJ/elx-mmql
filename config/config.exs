use Mix.Config

config :mmql,
  mq_type: :mqnats

# option for mqnats
config :mqnats,
  mqnats: %{
    host: "127.0.0.1",
    port: 4222,
    timeout: 6000
  }
