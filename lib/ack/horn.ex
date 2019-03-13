defmodule Ack.Horn do
  @moduledoc """
  The publisher, sending broadcasts when `ACK` is received. It serves three
    different channels:

  - `{Ack.Horn, :ack}` to send broadcast when the `ACK` comes
  - `{Ack.Horn, :nack}` to send broadcast when the `NACK` comes
  - `{Ack.Horn, :error}` to send broadcast when the client:
    - called back with the wrong key (`status: :invalid`)
    - called back with the unknown `ACK` value (`status: :unknown`)
    - did not called back and the timeout has expired.

  Host and client might agree on using more verbs besides `ACK` and `NACK`.
  To handle this the host should implement somewhat like the following clause:

  ```elixir
  def handle_envio(%{status: :unknown, key: key, value: verb} = message, state) do
    state = BusinessLogic.on_other_verb(key)
    {:noreply, state}
  end
  ```
  """
  use Envio.Publisher

  @doc false
  def ack(what), do: broadcast(:ack, what)
  @doc false
  def nack(what), do: broadcast(:nack, what)
  @doc false
  def error(what), do: broadcast(:error, what)
end
