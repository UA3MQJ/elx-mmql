defmodule MMQL.ConnectionSup do

  use Supervisor
  @name MMQL.ConnectionSup
  require Logger


  def start_link do
    Logger.debug  ">>> MMQL.ConnectionSup start_link"

    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def init(_arg) do
    Logger.debug  ">>> MMQL.ConnectionSup init"

    childrens = [
      worker(MMQL.Connection, [], restart: :permanent)
    ]

    supervise(childrens, strategy: :simple_one_for_one)
  end

  def add_connection(options) do
    Logger.debug  ">>> MMQL.add_connection options=#{inspect options}"

    Supervisor.start_child(@name, [options])
  end

end
