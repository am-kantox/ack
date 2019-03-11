defmodule AckTest do
  use ExUnit.Case
  use Plug.Test

  doctest Ack

  @opts Ack.Callback.Camarero.Handler.init([])

  test "Ack.listen/1" do
    conn =
      :post
      |> conn("/api/acknowledgements/callback", %{key: "42", value: :ack})
      |> Ack.Callback.Camarero.Handler.call(@opts)

    assert conn.status == 200

    Process.sleep(1_000)
  end
end
