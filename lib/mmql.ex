defmodule MMQL do
  defmacro __using__(_) do
    require Logger

    Logger.info "MMQL mq_type ..."

    case Application.get_env(:mmql, :mq_type) do
      :mqnats ->
        Logger.info "MMQL NATS"
        quote do: use MQNATS
      _ ->
        Logger.info "MMQL UNKNOWN"
    end

  end
end
