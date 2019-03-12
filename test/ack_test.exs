defmodule AckTest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest Ack

  @opts Ack.Camarero.Callback.Handler.init([])
  @opts_active Ack.Camarero.Active.Handler.init([])

  setup do
    ast =
      quote generated: true do
        use Envio.Subscriber, channels: [{Ack.Horn, :ack}, {Ack.Horn, :nack}, {Ack.Horn, :error}]

        def handle_envio(%{key: key, status: :ack} = message, state) do
          {:noreply, state} = super(message, state)
          send(unquote(self()), :ack)
          {:noreply, state}
        end

        def handle_envio(%{key: key, status: :nack} = message, state) do
          {:noreply, state} = super(message, state)
          send(unquote(self()), :nack)
          {:noreply, state}
        end

        def handle_envio(%{status: :unknown} = message, state) do
          {:noreply, state} = super(message, state)
          send(unquote(self()), :error)
          {:noreply, state}
        end

        def handle_envio(%{status: :invalid} = message, state) do
          {:noreply, state} = super(message, state)
          send(unquote(self()), :invalid)
          {:noreply, state}
        end

        def handle_envio(%{status: :timeout} = message, state) do
          {:noreply, state} = super(message, state)
          send(unquote(self()), :timeout)
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
    assert {:ok, %{timeout: 5_000}} = Ack.Active.plato_get("Ack.listen/1")
  end

  test "active" do
    Ack.listen(%{key: "active"})

    conn =
      :get
      |> conn("/api/acknowledgements/active/active")
      |> Ack.Camarero.Active.Handler.call(@opts_active)

    assert conn.status == 200
  end

  test "callback_ack" do
    Ack.listen(%{key: "callback_ack"})

    conn =
      :post
      |> conn("/api/acknowledgements/callback", %{key: "callback_ack", value: "ack"})
      |> Ack.Camarero.Callback.Handler.call(@opts)

    assert conn.status == 200

    assert_receive :ack
    assert Ack.Active.plato_get("callback_ack") == :error
  end

  test "callback_nack" do
    Ack.listen(%{key: "callback_nack"})

    conn =
      :post
      |> conn("/api/acknowledgements/callback", %{key: "callback_nack", value: "nack"})
      |> Ack.Camarero.Callback.Handler.call(@opts)

    assert conn.status == 200

    assert_receive :nack
    assert {:ok, %{timeout: 5_000}} = Ack.Active.plato_get("callback_nack")
  end

  test "callback_ko" do
    Ack.listen(%{key: "callback_ko"})

    conn =
      :post
      |> conn("/api/acknowledgements/callback", %{key: "not_existing", value: "ack"})
      |> Ack.Camarero.Callback.Handler.call(@opts)

    assert conn.status == 200

    assert_receive :invalid
  end

  test "timeout" do
    Ack.listen(%{key: "timeout", timeout: 50})
    assert_receive :timeout, 1_000
  end
end
