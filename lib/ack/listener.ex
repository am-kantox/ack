defmodule Ack.Listener do
  use Envio.Subscriber, channels: [{Camarero.Spitter, :all}]

  def handle_envio(message, state) do
    {:noreply, state} = super(message, state)
    IO.inspect(message, label: "Processed a request")
    {:noreply, state}
  end

  def handle_call(:state, _from, state), do: {:reply, state, state}
end
