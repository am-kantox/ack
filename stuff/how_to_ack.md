# ![Ack Logo](https://raw.githubusercontent.com/am-kantox/ack/master/stuff/i/logo-48.png)   Ack With Ease

## What?

`Ack` is designed to be a lightweight easy-to-use implementation of _interprocess acknowledgement_, whatever it means. According to [_Wikipedia_](https://en.wikipedia.org/wiki/Acknowledgement_(data_networks)):

> In data networking, telecommunications, and computer buses, an acknowledgement (_ACK_) is a signal passed between communicating processes, computers, or devices to signify acknowledgement, or receipt of message, as part of a communications protocol. The negative-acknowledgement (_NAK_ or _NACK_) signal is sent to reject a previously received message, or to indicate some kind of error. Acknowledgements and negative acknowledgements inform a sender of the receiver's state so that it can adjust its own state accordingly.

That said, when the independently running process is to pass a message around to another process—via some complicated pipe—that makes it hard to ensure that all parts of this pipe delivered the message successfully and/or instead of propagating the _success_/_failure_ back through each link in this chain, the sender might simply require _ACK_ back when the message was successfully delivered to the recipient.

This could involve the additional level of complexity when we are talking about tiny microservices. Not each and every microservice are to have a bucket of intercommunication clients included. Lightweight ones might have none in fact. This package is a drop-in solution for such cases.

_It probably does not apply when all involved processes come with messaging queue and fully-functional web server on board._

## Why?

This package comes with all the boilerplate included, including lightweight web-server based on [`Camarero`](https://hexdocs.pm/camarero/camarero.html) and process message broadcasting with [`Envío`](https://hexdocs.pm/envio). It drastically simplifies adding _ACK_ support to lightweight microservices. Indeed, all one needs would be to:

- add `Ack` to the list of applications started with `App1`
- implement [`Envio.Subscriber`](https://hexdocs.pm/envio/Envio.Subscriber.html) in `App1`, listening to any of three following channels:
  - `{Ack.Horn, :ack}`
  - `{Ack.Horn, :nack}`
  - `{Ack.Horn, :error}`
- implement `App2` to `HTTP POST` to `App1.domain:30009` one of two requests (assuming `key` is somewhat negotiated upgront and known to `App1`):
  - `%{"key" => key, "value" => "ack"}` to `ack`, or
  - `%{"key" => key, "value" => "nack"}` to `nack`

The control flow of each _ACK_ would be as shown below.

![Ack Message Lifetime](https://raw.githubusercontent.com/am-kantox/ack/master/stuff/i/ack.png)

The _whole_ implementation required from `App1` to start supporting _ACKs_ would look like (besides the business logic handling _ACKs_ and _NACKs_):

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

To start expecting for the _ACK_, one simple calls `Ack.listen/1` passing the following map as a parameter of a type `Ack.t`:

```elixir
Ack.listen(%{key: "user_123", timeout: 5_000})
```

When the callback with a payload having `%{}` will be received, the message will be broadcasted to all the pub-sub listeners of one of aforementioned `Ack.Horn` channels, depending on the state.

---

The _whole_ implementation required from `App2` to start supporting _ACKs_ would be to _HTTP POST_ to the predefined endpoint the message of a shape `%{key: entity_id, value: :ack or :nack}`.

That’s it.

## Why not?

In many [over]complicated systems there are already robust queue-based ack-back pipelines presented. If the whole system already has the intercommunication pipeline, providing back-and-forth validation and monitoring of everything, `Ack` would most likely not suit. Still, it’s robust and comprehensive.

## Is it of any good?

Sure, it is.
