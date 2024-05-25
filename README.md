# ![Ack Logo](https://raw.githubusercontent.com/am-kantox/ack/master/stuff/i/logo-48.png)   Ack [![Kantox ❤ OSS](https://img.shields.io/badge/❤-kantox_oss-informational.svg)](https://kantox.com/)  ![Test](https://github.com/am-kantox/ack/workflows/Test/badge.svg)  ![Dialyzer](https://github.com/am-kantox/ack/workflows/Dialyzer/badge.svg)

**Tiny drop-in for painless acknowledgements across different applications.**

## About

![Ack Message Lifetime](https://raw.githubusercontent.com/am-kantox/ack/master/stuff/i/ack.png)

To implement `ack` support between two applications, one might use `Ack` application with a very little amount of code needed.

Imagine we have two applications, `App1` and `App2` as shown above. When `App1` sends _something_ to `App2` it might require the acknowledgement back confirming the successful processing of this _something_. For instance, `App1` might call an API endpoint of `App2`, which triggers a long process, or it might place a message into RabbitMQ and expect to receive an `ack` to perform some cleanup, or whatever.

Using `Ack`, one should only:

- add `Ack` to the list of applications started with `App1`
- implement [`Envio.Subscriber`](https://hexdocs.pm/envio/Envio.Subscriber.html) in `App1`, listening to any of three following channels:
  - `{Ack.Horn, :ack}`
  - `{Ack.Horn, :nack}`
  - `{Ack.Horn, :error}`
- implement `App2` to `HTTP POST` to `App1.domain:30009` one of two requests (assuming `key` is somewhat negotiated upgront and known to `App1`):
  - `%{"key" => key, "value" => "ack"}` to `ack`, or
  - `%{"key" => key, "value" => "nack"}` to `nack`

That’s it.

## Installation

The package can be installed by adding `ack` to your list of dependencies **and** applications in `mix.exs`:

```elixir
def deps, do: [{:ack, "~> 0.1"}, ...]
def applications, do: applications: [:logger, ..., :ack, ...]
```

## [Documentation](https://hexdocs.pm/ack)
