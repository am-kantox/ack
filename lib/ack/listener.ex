defmodule Ack.Listener do
  @moduledoc false
  use Envio.Subscriber, channels: [{Camarero.Spitter, :all}]

  @impl true
  def handle_envio(
        %{conn: %Plug.Conn{params: %{"key" => key, "value" => value}}} = message,
        state
      ) do
    {:noreply, state} = super(message, state)

    do_handle_envio(value, key)

    {:noreply, state}
  end

  defp do_handle_envio("ack", key) do
    case Ack.Active.plato_get(key) do
      {:ok, %{channel: :ack}} ->
        Ack.Active.plato_delete(key)
        Ack.Horn.ack(%{status: :ack, key: key})

      :error ->
        Ack.Horn.error(%{status: :invalid, key: key})
    end
  end

  defp do_handle_envio("nack", key) do
    Ack.Horn.nack(%{status: :nack, key: key})
  end

  defp do_handle_envio(unknown, key) do
    Ack.Horn.error(%{status: :unknown, key: key, value: unknown})
  end

  @doc false
  def handle_call(:state, _from, state), do: {:reply, state, state}
end
