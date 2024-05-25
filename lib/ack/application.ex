defmodule Ack.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: Ack.TaskSupervisor},
      {Ack.Listener, []}
    ]

    opts = [strategy: :one_for_one, name: Ack.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
