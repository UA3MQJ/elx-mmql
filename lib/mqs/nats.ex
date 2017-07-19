defmodule Mmql.Mqs.Nats do

  use GenServer

  require Logger

  @service_name NatsService

  def send_text(text) do
    Logger.debug ">>> Mmql.Mqs.Nats send text=#{inspect text}"
    GenServer.cast(__MODULE__, {:send_text, text})
  end

  def start_link(nats_params) do
    Logger.debug ">>> Mmql.Mqs.Nats start_link nats_params=#{inspect nats_params}"
    GenServer.start_link(__MODULE__, [nats_params], [{:name, __MODULE__}])
  end

  def init([nats_params]) do
    Logger.debug ">>> Mmql.Mqs.Nats init nats_params=#{inspect nats_params}"

    state =
      %{
        nats_pid: nil,
        nats_params: nats_params,
	nats_status: :disconnected
       }
    
    GenServer.cast(__MODULE__, :connect)

    {:ok, state}
  end

  def handle_cast(:connect, state) do
    Logger.debug ">>> Mmql.Mqs.Nats Connecting to NATS..."
    nats_params = state.nats_params
    case Nats.Client.start_link(@service_name, nats_params) do
      {:ok, nats_pid} ->
	Logger.debug ">>> Mmql.Mqs.Nats Connecting to NATS: success"
        Logger.debug ">>> sub #{inspect nats_params.subject}"
	result = Nats.Client.sub(@service_name, self(), nats_params.subject)
	Logger.debug "result=#{inspect result}"
	{:noreply, %{state| nats_pid: nats_pid, nats_status: :connected}}
      error ->
        Logger.error ">>> Mmql.Mqs.Nats Connect error=#{inspect error}"
        {:noreply, state}
    end
  end

  def handle_cast({:send_text, text}, state) do
    Logger.debug ">>> Mmql.Mqs.Nats cast send_text #{inspect state.nats_params.subject}"
    :ok = Nats.Client.pub(@service_name, state.nats_params.subject, text)
    {:noreply, state}
  end

  def handle_info({:msg, _, _subject, _reply, _request} = msg, state) do
    Logger.debug ">>> Mmql.Mqs.Nats :msg #{inspect msg}"

    {:noreply, state}
  end
end
