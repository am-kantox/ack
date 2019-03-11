use Mix.Config

config :camarero,
  cowboy: [port: 3009, scheme: :http, options: []],
  carta: [Ack.Callback, Ack.Active],
  root: "api/acknowledgements"
