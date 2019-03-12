defmodule Ack.Active do
  @moduledoc false
  use Camarero, as: Ack.Camarero.Active, methods: :get
end

defmodule Ack.Callback do
  @moduledoc false
  use Camarero, as: Ack.Camarero.Callback, methods: :post
end
