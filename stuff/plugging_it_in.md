# ![Ack Logo](https://raw.githubusercontent.com/am-kantox/ack/master/stuff/i/logo-48.png)   Plugging Ack In

## Standalone Cowboy

When the _ack-back_ functionality is to be added to the standalone microservice, having no webserver on board, `Ack` (in fact, underlying [`Camarero`](https://hexdocs.pm/camarero/camarero.html) instance) should be configured to start `cowboy` server underneath. Put this in your mix configuration:

```elixir
config :camarero,
  cowboy: [port: 4001, options: []], # options are passed to cowboy plug
  carta: [Ack.Callback, Ack.Active], # list of handlers/endpoints
  root: "api/v2"                     # root location to serve requests
```

### Keyword options

#### `cowboy:`

For the list of options that can be passed, see [`plug_cowboy` docs](https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#module-options).

#### `carta:`

Here we might specify any amount of different [`camarero` handlers](https://hexdocs.pm/camarero/camarero.html#handlers). `[Ack.Callback, Ack.Active]` is the default value for those, but one might easily everwrite/extend this list with other endpoints.

- `Ack.Callback` is the handler/endpoint for callbacks, accepting `POST` requests of a shape `%{key: <ID>, value: <ACK> | <NACK>}` only, available at the path `"#{root}/callback"`.
- `Ack.Active` accepts `GET` only and exports the map of callbacks currently being awaited, available at the path `"#{root}/active"`.

#### `root:`

The root location where the plug handler(s) will be served.

### Listener

`Ack` comes with it’s own [`Registry`](https://hexdocs.pm/elixir/Registry.html), provided by [`Envio`](https://hexdocs.pm/envio/).

To place the callback into the map of active expectations, call `Ack.listen/1`. It accepts a map, having two parameters, mandatory `key` and optional `timeout`, defaulted to `5_000` (ms.)

---

When the `POST` request is issued to the callback endpoint, it’s being processed as shown below:

- if the `key` is not known to `Ack` _or_ if the `value` is neither `"ack"` nor `"nack"`, the broadcast is sent to all the subscribers (see below) through `{Ack.Horn, :error}` channel, with all the corresponding data.
- if the `value` is `"ack"`, the respective key _is removed_ from the _expecting callbacks_ map and the broadcast is sent through `{Ack.Horn, :ack}` channel.
- if the `value` is `"nack"`, the respective key _is **not** removed_ from the _expecting callbacks_ map and the broadcast is sent through `{Ack.Horn, :nack}` channel.

If there was no callback within the desired timeout, the broadcast with `status: :timeout` is being sent through `{Ack.Horn, :error}` and the respective key _is **not** removed_ from the _expecting callbacks_ map (this might be changed in the future.)

#### List of possible statuses

- `ack` (`{Ack.Horn, :ack}` channel) the remote issued `ack`, _everything is fine_
- `nack` (`{Ack.Horn, :nack}`) the remote issued `nack`, meaning it expects us to resend the data
- `invalid` (`{Ack.Horn, :error}`) there is no such `key` in the list of active expectaions
- `unknown` (`{Ack.Horn, :error}`) the remote sent the unknown term (nether `nack` nor `ack`)
- `timeout` (`{Ack.Horn, :error}`) the remote did not respond withing the specified timeout

### Subscriber(s)

To subscribe to the callback notifications, one should implement an [`Envio.Subscriber`](https://hexdocs.pm/envio/Envio.Subscriber.html) behaviour. The easiest way would be to use scaffold:

```elixir
defmodule MyApp.AckHandler do
  use Envio.Subscriber,
    channels: [{Ack.Horn, :ack}, {Ack.Horn, :nack}, {Ack.Horn, :error}]

  def handle_envio(%{key: key, status: status} = message, state) do
    state = BusinessLogic.on_response(status, for: key)
    {:noreply, state}
  end
end
```

### The summing up

The application hosting `Ack` implements one or more subscribers as shown above. When the `ACK` is required, it places it to the list of expectations with a call to `Ack.listen/1`. When the `ACK` arrives, or after the timeout (what comes earlier) all the subscribers do receive _an envío_.

The client application performs an `HTTP` post to the respective endpoint with a payload of a shape `%{key: <ID>, value: <ACK> | <NACK>}`. The contracting parties might use _other_ types of `ACK` statuses, assuming the host handles the respective `handle_envio(%{status: status}, _)` properly.

## Phoenix Integration

To use `Ack` with [`Phoenix`](https://phoenixframework.org/), one should follow the steps above. The only difference would be, instead of spawning `cowboy`, we should add this line to _Phoenix_ `routes.ex` file:

```elixir
forward("/api/ack", Ack.Camarero.Handler)
```

The `root` option of _Camarero_ config is now relative to the first parameter in the call above. To keep routing simple, we suggest the setting `confir :camarero, root: ""`.

Now `/api/ack/callback` would be the _callback_ endpoint and `/api/ack/active` would be the _active_ endpoint respectively.

That’s it!
