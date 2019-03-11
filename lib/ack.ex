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

  ```elixir
  %{id: id, timeout: msecs, channel: :ack}
  ```

  where `id` is the unique identifier of the message to be acknowledged.
  Upon receival `Ack` will broadcast the message to `:ack` channel. `App1`
  should be subscribed to `{Ack.Horn, :ack}` channel in order to receive
  this message.

  The broadcast is done with [`Envío`](https://hexdocs.pm/envio/envio.html)
    package, consider reading the documentation there to get more details about
    subscriptions.

  Currently only HTTP endpoint is supported for ack callbacks.
  """

  @doc """
  Hello world.

  ## Examples


  """
  @spec listen(map()) :: :ok | {:error, term()}
  def listen(%{id: id} = params) do
    timeout = Map.get(params, :timeout, 5_000)
    channel = Map.get(params, :channel, :ack)

    Ack.Active.plato_put(id, %{timeout: timeout, channel: channel})
  end
end
