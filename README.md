# MMQL - Multi MQ library
![Wrapper for MQ](http://b.repl.ca/v1/Wrapper_for-MQ-blue.png)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://travis-ci.org/UA3MQJ/elx_mmql.svg?branch=master)](https://travis-ci.org/UA3MQJ/elx_mmql?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/UA3MQJ/elx_mmql/badge.svg?branch=master)](https://coveralls.io/github/UA3MQJ/elx_mmql?branch=master)
[![Inline docs](http://inch-ci.org/github/UA3MQJ/elx_mmql.svg)](http://inch-ci.org/github/UA3MQJ/elx_mmql)

Universal library-application wrapper for working with MQ servers

MQ support list:
 * NATS via https://github.com/nats-io/elixir-nats
 * MQTT via https://github.com/suvash/hulaaki

## Installation
In mix.exs file
```elixir
def deps do
  [:mmql, git: "https://github.com/UA3MQJ/elx-mmql.git"]
end
```

## Use
Set config.exs of MQ servers.

```elixir
config :mmql,
  options: %{
    connections: %{
      "A" => %{               # A - connection name
        mq_type: :mqnats,     # MQ type :mqnats for NATS
        autoconnect: false,   # Autoconnect 
        host: "127.0.0.1",
        port: 4222,
        timeout: 6000
      },

      "B" => %{               # B - connection name
        mq_type: :mqmqtt,     # MQ type :mqmqtt for MQTT
        autoconnect: true,
        host: "127.0.0.1",
        port: 1883
      }
    }
  }
```

```elixir
  MMQL.connect("A")            # "A" - connection name. connect to MQ server (no need if autoconnect is true)
  MMQL.sub("A", "topic")       # subscribe to "topic" on "A" connection
  MMQL.pub("A", "topic", "message") # publish message
  
  # receive subscribed message
  
  # in code
    receive do
      {:subscribed_publish, conn_name, topic, msg} ->
        # your code
        ....
      after
        2_000 ->
          throw("msg not received")
    end
    
  # in gen_server
  def handle_info({:subscribed_publish, conn_name, topic, msg}, state) do
     # your code
     ...
    {:noreply, state}
  end
```

