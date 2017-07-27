defmodule MMQL.MQ.NATS do
   
  use GenServer
  require Logger

  def start_link(options) do
    Logger.debug  ">>> MMQL.MQ.NATS start_link options = #{inspect options}"

    GenServer.start_link(__MODULE__, [options])
  end

  def connect(pid) do
    Logger.debug  ">>> MMQL.MQ.NATS connect pid = #{inspect pid}"
    GenServer.call(pid, :connect)
  end

  def init([options]) do
    Logger.debug  ">>> MMQL.MQ.NATS init options = #{inspect options}"

    state = %{
      options: options,
      nats_pid: nil,
      nats_status: :disconnected,
      subj2ref: %{}
    }

    {:ok, state}
  end

  def handle_call(:connect, _from, %{:nats_status => :connected} = state) do
    {:reply, {:error, :already_connected}, state}
  end
  def handle_call(:connect, _from, state) do
    Logger.debug  ">>> MMQL.MQ.NATS handle_call connect"

    nats_config = %{
      host: state.options.host,
      port: state.options.port,
      timeout: state.options.timeout
    }
    Logger.debug  ">>> MMQL.MQ.NATS nats_config = #{inspect nats_config}"

    case Nats.Client.start_link(nats_config) do
      {:ok, nats_pid} ->
        {:reply, {:ok, %{nats_pid: nats_pid}}, %{state| nats_pid: nats_pid, nats_status: :connected}}
      error ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_call(:disconnect, _from, %{:nats_status => :disconnected} = state) do
    {:reply, {:error, :not_connected}, state}
  end
  def handle_call(:disconnect, _from, state) do
    Logger.debug  ">>> MMQL.MQ.NATS handle_call disconnect"

    Nats.Client.stop(state.nats_pid)
    {:reply, :ok, %{state| nats_pid: nil, nats_status: :disconnected, subj2ref: %{}}}
  end

  def handle_call({:subscribe, _topic, _pid}, _from, %{:nats_status => :disconnected} = state) do
    {:reply, {:error, :not_connected}, state}
  end
  def handle_call({:subscribe, topic}, _from, state) do
    Logger.debug  ">>> MMQL.MQ.NATS handle_call subscribe"

    {:ok, ref} = Nats.Client.sub(state.nats_pid, self(), topic)
    Logger.debug  ">>> MMQL.MQ.NATS result = #{inspect ref}"
    new_subj2ref = Map.merge(state.subj2ref, %{topic => ref})

    {:reply, {:ok, ref}, %{state| subj2ref: new_subj2ref}}
  end

  def handle_call({:unsubscribe, _topic}, _from, %{:nats_status => :disconnected} = state) do
    {:reply, {:error, :not_connected}, state}
  end
  def handle_call({:unsubscribe, topic}, _from, state) do
    Logger.debug  ">>> MMQL.MQ.NATS handle_call unsubscribe"

    case state.subj2ref[topic] do
      # subscription not exist
      nil ->
        {:reply, {:error, :subscription_no_exist}, state}
      ref ->
        Logger.debug "unsub ref=#{inspect ref}"
        case Nats.Client.unsub(state.nats_pid, ref, topic) do
          :ok ->
            new_subj2ref = Map.delete(state.subj2ref, topic)
            {:reply, :ok, %{state | subj2ref: new_subj2ref}}
          error ->
            {:reply, {:error, error}, state}
        end
    end
  end

  def handle_call({:publish, _topic, _message}, _from, %{:nats_status => :disconnected} = state) do
    {:reply, {:error, :not_connected}, state}
  end
  def handle_call({:publish, topic, message}, _from, state) do
    Logger.debug  ">>> MMQL.MQ.NATS handle_call publish topic = #{inspect topic} message = #{inspect message}"

    :ok = Nats.Client.pub(state.nats_pid, topic, message)

    {:reply, :ok, state}
  end

  # receive sub
  def handle_info({:msg, ref, topic, _reply, message} = msg, state) do
    Logger.debug  ">>> MMQL.MQ.NATS handle_info :msg msg=#{inspect msg}"
    
    MMQL.HUB.rcv_from_ref(ref, topic, message)

    {:noreply, state}
  end

end
