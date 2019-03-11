defmodule Ack.Horn do
  use Envio.Publisher, channel: :error

  def error(what), do: broadcast(what)
  def ok(channel, what), do: broadcast(channel, what)
end
