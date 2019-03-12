defmodule Ack.Callback do
  @moduledoc false
  use Camarero, as: Ack.Camarero, methods: :post
end

defmodule Ack.Active do
  @moduledoc false
  use Camarero, as: Ack.Camarero, methods: :get
end
