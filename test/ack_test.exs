defmodule AckTest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest Ack

  @opts Ack.Callback.Camarero.Handler.init([])

  setup do
    ast =
      quote generated: true do
        use Envio.Subscriber, channels: [{Ack.Horn, :ack}, {Ack.Horn, :error}]

        def handle_envio(%{key: "callback", status: :ok, value: :ack} = message, state) do
          {:noreply, state} = super(message, state)
          send(unquote(self()), {:ok, "callback", :ack})
          {:noreply, state}
        end
      end

    Code.compiler_options(ignore_module_conflict: true)
    {:module, mod, _, _} = Module.create(Sucker, ast, __ENV__)
    Code.compiler_options(ignore_module_conflict: false)
    {:ok, pid} = mod.start_link()

    on_exit(fn ->
      Sucker.terminate(:normal, Envio.Channels.state())
    end)

    %{pid: pid}
  end

  test "Ack.listen/1" do
    Ack.listen(%{key: "Ack.listen/1"})
    assert Ack.Active.plato_get("Ack.listen/1") == {:ok, %{channel: :ack, timeout: 5000}}
  end

  test "callback" do
    Ack.listen(%{key: "callback"})

    conn =
      :post
      |> conn("/api/acknowledgements/callback", %{key: "callback", value: :ack})
      |> Ack.Callback.Camarero.Handler.call(@opts)

    assert conn.status == 200

    assert_receive {:ok, "callback", :ack}
    assert Ack.Active.plato_get("callback") == :error
  end
end
