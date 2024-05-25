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

  - `%{key: key, timeout: msecs}`

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

  @timeout 5_000

  @type t() :: %{key: String.t(), timeout: timeout()}

  @doc """
  Adds a listener for the key with a timeout specified (defaults to `5` sec.)
  """
  @spec listen(t()) :: :ok | {:error, term()}
  def listen(%{key: key} = params) do
    key = to_string(key)

    params = %{
      key: key,
      timeout: Map.get(params, :timeout, @timeout),
      timestamp: DateTime.utc_now()
    }

    wait_for_response(params)
    Ack.Active.plato_put(key, params)
  end

  defp wait_for_response(%{key: key, timeout: timeout}) do
    Task.Supervisor.async(Ack.TaskSupervisor, fn ->
      Process.sleep(timeout)

      case Ack.Active.plato_get(key) do
        {:ok, %{timestamp: ts}} ->
          maybe_ack(DateTime.diff(DateTime.utc_now(), ts, :millisecond) > timeout, key)

        :error ->
          :ok
      end
    end)
  end

  defp maybe_ack(true, key), do: Ack.Horn.ack(%{status: :timeout, key: key})
  defp maybe_ack(false, _key), do: :ok
end
