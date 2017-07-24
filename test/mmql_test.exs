defmodule MMQLTest do
  require Logger
  use ExUnit.Case

  use MMQL

  test "create" do
    Process.register(self(), :mq_nats_tester)

    {:ok, pid} = start_link()
   
    assert {:ok, _nats_pid} = connect(pid)
    assert {:ok, _ref}      = subscribe(pid, "event")
    assert :ok              = publish(pid, "event", "test event")
    
    receive do
      %{subject: subject, message: message} ->
        Logger.info "***** RCVD : subject = #{inspect subject} message = #{inspect message}"
        assert subject = "event"
        assert message = "test event"
      after
        2_000 ->
          Logger.info "***** RCVD - timeout"
          throw("msg not received")
    end

    assert res = unsubscribe(pid, "event")
    Logger.debug ">>>>>>> unsubscribe res=#{inspect res}"

    
    assert res = unsubscribe(pid, "event")
    Logger.debug ">>>>>>> unsubscribe res=#{inspect res}"

    assert :ok = disconnect(pid)
  end

  def on_connect(info) do
    Logger.debug ">>>>>>> CALLBACK on_connect info=#{inspect info}"
  end

  def on_disconnect() do
    Logger.debug ">>>>>>> CALLBACK on_disconnect"
  end

  def on_subscribe(info) do
    Logger.debug ">>>>>>> CALLBACK on_subscribe info=#{inspect info}"
  end

  def on_unsubscribe(info) do
    Logger.debug ">>>>>>> CALLBACK on_unsubscribe info=#{inspect info}"
  end

  def on_subscribed_publish(info) do
    Logger.debug ">>>>>>> CALLBACK on_subscribed_publish  info=#{inspect info}"
    case Process.whereis(:mq_nats_tester) do
      nil ->
        :ok # nothing to do
      pid ->
        send(pid, info)
      :ok
    end
  end
  
  def on_publish(info) do
    Logger.debug ">>>>>>> CALLBACK on_publish  info=#{inspect info}"
  end

end
