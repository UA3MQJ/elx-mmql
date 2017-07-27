defmodule MMQL.HUB do
  require Logger
  use GenServer

  @hub_proc_name "MMQL.HUB"

  def start_link do
    Logger.debug  ">>> MMQL.HUB start_link"    
    GenServer.start_link(__MODULE__, [])  
  end

  def init([]) do
    Logger.debug  ">>> MMQL.HUB init"
    options = Application.get_env(:mmql, :options)

    true = :gproc.add_local_name(@hub_proc_name)

    :gproc.reg(gproc_key("event"))

    send(self(), :init)

    state = %{
        options: options,
        ref2subscriber: %{}
    }
    {:ok, state}
  end

  def broadcast(topic, message) do
    Logger.debug  ">>> MMQL.HUB send broadcast topic=#{inspect topic} message=#{inspect message}"
    GenServer.cast({:via, :gproc, gproc_key(topic)}, {:broadcast, message})
  end

  # store pid of process, who subscribe
  def reg_ref(subscriber_pid, ref, conn_name, topic) do
    GenServer.cast({:via, :gproc, {:n, :l, @hub_proc_name}}, {:reg_ref, subscriber_pid, ref, conn_name, topic})
  end

  # receive msg from ref -> proc
  def rcv_from_ref(ref, topic, message) do
    GenServer.cast({:via, :gproc, {:n, :l, @hub_proc_name}}, {:rcv_from_ref, ref, topic, message})
  end

  def handle_cast({:broadcast, message}, state) do
    Logger.debug  ">>> MMQL.HUB rcv broadcast message=#{inspect message}"
    {:noreply, state}
  end

  def handle_cast({:reg_ref, subscriber_pid, ref, conn_name, topic}, state) do
    Logger.debug  ">>> MMQL.HUB reg_ref subscriber_pid=#{inspect subscriber_pid} "
               <> "topic=#{inspect topic} ref=#{inspect subscriber_pid}"
  
    subscribe_info =%{
      subscriber_pid: subscriber_pid,
      topic: topic,
      ref: ref,
      connection_name: conn_name
    }

    new_ref2subscriber = Map.merge(state.ref2subscriber, %{ref => subscribe_info})
    {:noreply, %{state | ref2subscriber: new_ref2subscriber}}
  end

  def handle_cast({:rcv_from_ref, ref, topic, message}, state) do
    Logger.debug  ">>> MMQL.HUB rcv_from_ref ref=#{inspect ref} "
               <> "topic=#{inspect topic} message=#{inspect message}"

    case state.ref2subscriber[ref] do
      nil ->
        Logger.debug  ">>> MMQL.HUB unknown reference"
      subscribe_info ->
        Logger.debug  ">>> MMQL.HUB subscribe_info=#{inspect subscribe_info}"
        send(subscribe_info.subscriber_pid, 
             {:subscribed_publish, subscribe_info.connection_name, topic, message})
    end
  
    {:noreply, state}
  end

  # delayed init with load configured connections
  def handle_info(:init, state) do
    Logger.debug  ">>> MMQL.HUB delayed :init state=#{inspect state}"

    Enum.map(state.options.connections, fn({name, opts}) ->
      MMQL.ConnectionSup.add_connection(%{name: name, options: opts})
    end)

    {:noreply, state}
  end

  defp gproc_key(topic) do
    {:p, :l, topic}
  end

end
