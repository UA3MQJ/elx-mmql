defmodule MMQLTest do
  require Logger
  use ExUnit.Case

  test "config" do
    conn_name = "A"
    topic = "topic"
    msg = "message"
    assert {:ok, _info} = MMQL.connect(conn_name)
    MMQL.sub(conn_name, topic)
    MMQL.pub(conn_name, topic, msg)
    receive do
      {:subscribed_publish, ^conn_name, ^topic, ^msg} ->
        :ok
      _else ->
        throw("error rcvd conn_name, topic or msg")
      after
        2_000 ->
          throw("msg not received")
    end
    
    MMQL.usub(conn_name, topic)
    MMQL.pub(conn_name, topic, msg)
    receive do
      _ ->
        throw("msg received")
      after
        1_000 ->
          :ok
    end

    :timer.sleep(1000)
  end

end
