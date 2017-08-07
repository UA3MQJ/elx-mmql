defmodule MMQL.MQ.NATS do
  @moduledoc """
  Module for connecting with MQ NATS
  """

  use GenServer

  def start_link(options) do
    GenServer.start_link(__MODULE__, [options])
  end

  def connect(pid) do
    GenServer.call(pid, :connect)
  end

  def init([options]) do
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
    nats_config = %{
      host: state.options.host,
      port: state.options.port,
      timeout: state.options.timeout
    }

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
    Nats.Client.stop(state.nats_pid)
    {:reply, :ok, %{state| nats_pid: nil, nats_status: :disconnected, subj2ref: %{}}}
  end

  def handle_call({:subscribe, _topic, _pid}, _from, %{:nats_status => :disconnected} = state) do
    {:reply, {:error, :not_connected}, state}
  end
  def handle_call({:subscribe, topic, pid}, _from, state) do
    {:ok, ref} = Nats.Client.sub(state.nats_pid, self(), topic)
    new_subj2ref = Map.merge(state.subj2ref, %{{topic, pid} => ref})

    {:reply, {:ok, ref}, %{state| subj2ref: new_subj2ref}}
  end

  def handle_call({:unsubscribe, _topic, _pid}, _from, %{:nats_status => :disconnected} = state) do
    {:reply, {:error, :not_connected}, state}
  end
  def handle_call({:unsubscribe, topic, pid}, _from, state) do
    case state.subj2ref[{topic, pid}] do
      # subscription not exist
      nil ->
        {:reply, {:error, :subscription_no_exist}, state}
      ref ->
        case Nats.Client.unsub(state.nats_pid, ref, topic) do
          :ok ->
            new_subj2ref = Map.delete(state.subj2ref, {topic, pid})
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
    :ok = Nats.Client.pub(state.nats_pid, topic, message)
    {:reply, :ok, state}
  end

  # receive sub
  def handle_info({:msg, ref, topic, _reply, message}, state) do
    MMQL.HUB.rcv_from_ref(ref, topic, message)
    {:noreply, state}
  end

end
