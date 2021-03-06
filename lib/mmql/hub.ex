defmodule MMQL.HUB do
  
  use GenServer

  @hub_proc_name "MMQL.HUB"

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    options = Application.get_env(:mmql, :options)

    true = :gproc.add_local_name(@hub_proc_name)

    send(self(), :init) # delayed init with load connections opts

    state = %{
        options: options,
        ref2subscriber: %{},
        pt2ref: %{}
    }
    {:ok, state}
  end

  # store pid of process, who subscribe
  def reg_ref(subscriber_pid, ref, conn_name, topic) do
    GenServer.cast({:via, :gproc, {:n, :l, @hub_proc_name}}, {:reg_ref, subscriber_pid, ref, conn_name, topic})
  end

  # remove pid
  def unreg_ref(s_pid, conn_name, topic) do
    GenServer.cast({:via, :gproc, {:n, :l, @hub_proc_name}}, {:unreg_ref, s_pid, conn_name, topic})
  end

  # receive msg from ref -> proc
  def rcv_from_ref(ref, topic, message) do
    GenServer.cast({:via, :gproc, {:n, :l, @hub_proc_name}}, {:rcv_from_ref, ref, topic, message})
  end

  def handle_cast({:reg_ref, subscriber_pid, ref, conn_name, topic}, state) do
    subscribe_info =%{
      subscriber_pid: subscriber_pid,
      topic: topic,
      ref: ref,
      connection_name: conn_name
    }

    new_ref2subscriber = Map.merge(state.ref2subscriber, %{ref => subscribe_info})
    new_pt2ref = Map.merge(state.pt2ref, %{{subscriber_pid, topic} => ref})
    {:noreply, %{state | ref2subscriber: new_ref2subscriber, pt2ref: new_pt2ref}}
  end

  def handle_cast({:unreg_ref, s_pid, _conn_name, topic}, state) do
    {new_ref2subscriber, new_pt2ref} = case state.pt2ref[{s_pid, topic}] do
       nil ->
         {state.ref2subscriber, state.pt2ref}
       ref ->
         {Map.delete(state.ref2subscriber, ref), Map.delete(state.pt2ref, {s_pid, topic})}
    end
    {:noreply, %{state | ref2subscriber: new_ref2subscriber, pt2ref: new_pt2ref}}
  end

  def handle_cast({:rcv_from_ref, ref, topic, message}, state) do
    case state.ref2subscriber[ref] do
      nil ->
        :unknown_reference # nobody known about it ;)
      subscribe_info ->
        send(subscribe_info.subscriber_pid, 
             {:subscribed_publish, subscribe_info.connection_name, topic, message})
    end
  
    {:noreply, state}
  end

  # delayed init with load configured connections
  def handle_info(:init, state) do
    Enum.map(state.options.connections, fn({name, opts}) ->
      MMQL.ConnectionSup.add_connection(%{name: name, options: opts})
    end)

    {:noreply, state}
  end

end
