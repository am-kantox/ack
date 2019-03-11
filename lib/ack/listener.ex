defmodule Ack.Listener do
  @moduledoc false
  use Envio.Subscriber, channels: [{Camarero.Spitter, :all}]

  @impl true
  def handle_envio(
        %{conn: %Plug.Conn{params: %{"key" => key, "value" => value}}} = message,
        state
      ) do
    {:noreply, state} = super(message, state)

    case Ack.Active.plato_get(key) do
      {:ok, %{channel: channel}} ->
        Ack.Horn.ok(channel, %{status: :ok, key: key, value: value})
        Ack.Active.plato_delete(key)

      :error ->
        Ack.Horn.error(%{status: :error, key: key, value: value})
    end

    {:noreply, state}
  end

  @doc false
  def handle_call(:state, _from, state), do: {:reply, state, state}
end
