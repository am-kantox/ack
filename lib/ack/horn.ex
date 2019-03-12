defmodule Ack.Horn do
  @moduledoc false
  use Envio.Publisher

  def ack(what), do: broadcast(:ack, what)
  def nack(what), do: broadcast(:nack, what)
  def error(what), do: broadcast(:error, what)
end
