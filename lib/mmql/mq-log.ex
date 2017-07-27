defmodule MMQL.MQLog do
  require Logger
  use GenServer

  def start_link do
    Logger.debug  ">>> MMQL.MQLog start_link"    

    GenServer.start_link(__MODULE__, [])  
  end

  def init([]) do
    Logger.debug  ">>> MMQL.MQLog init"
    options = Application.get_env(:mmql, :options)

    true = :gproc.add_local_name("MMQL.MQLog")

    :gproc.reg(gproc_key("event"))

    state = %{options: options}
    {:ok, state}
  end

  def handle_cast({:broadcast, message}, state) do
    Logger.debug  ">>> MMQL.MQLog rcv broadcast message=#{inspect message}"
    {:noreply, state}
  end

  defp gproc_key(topic) do
    {:p, :l, topic}
  end
  
end
