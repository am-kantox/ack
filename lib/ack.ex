defmodule Ack do
  @moduledoc """
  `Ack` is a tiny application that might be used as drop-in to handle
    acknowledgments between processes.

  When `App1` sends _something_ to `App2` it might require the acknowledgement
    back confirming the successful processing of this _something_. For instance,
    `App1` might call an API endpoint of `App2`, which triggers a long process,
    or it might place a message into RabbitMQ and expect to receive an `ack` to
    perform some cleanup, or whatever.

  In this scenario, `App1` might instruct `Ack` to listen for the `ack` from
    `App2` for a message

  - `%{key: key, timeout: msecs, channel: :ack}`

  where `key` is the unique identifier of the message to be acknowledged.
  Upon receival, if the `key` is known to the system, `Ack` will broadcast
  the message of the following shape

  - `%{status: :ack, key: key}`

  to `:ack` channel. `App1` should be subscribed to `{Ack.Horn, :ack}` channel
  in order to receive this message.

  If the `key` is unknown to the system, on of the following possible messages

  - `%{status: :nack, key: key}`, when the `key` was explicitly not acked
  - `%{status: :invalid, key: key}`, when the `key` is not known to the system
  - `%{status: :unknown, key: key, value: value}`, when somewhat unexpected happened

  The former one os routed to `{Ack.Horn, :nack}` channel, the last two
  are broadcasted to `{Ack.Horn, :error}` channel.

  The broadcast is done with [`Envío`](https://hexdocs.pm/envio/envio.html)
    package, consider reading the documentation there to get more details about
    subscriptions.

  Currently only HTTP endpoint is supported for ack callbacks.
  """

  @doc """
  Hello world.

  ## Examples


  """
  @timeout 5_000
  @channel :ack

  @spec listen(map()) :: :ok | {:error, term()}
  def listen(%{key: key} = params) do
    Ack.Active.plato_put(to_string(key), %{
      timeout: Map.get(params, :timeout, @timeout),
      channel: Map.get(params, :channel, @channel)
    })
  end
end
