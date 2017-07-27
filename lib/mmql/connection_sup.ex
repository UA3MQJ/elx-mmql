defmodule MMQL.ConnectionSup do

  use Supervisor
  @name MMQL.ConnectionSup

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  def init(_arg) do
    childrens = [
      worker(MMQL.Connection, [], restart: :permanent)
    ]

    supervise(childrens, strategy: :simple_one_for_one)
  end

  def add_connection(options) do
    Supervisor.start_child(@name, [options])
  end

end
