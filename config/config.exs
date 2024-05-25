import Config

config :camarero,
  carta: [Ack.Callback, Ack.Active],
  root: ""

if File.exists?("config/#{Mix.env()}.exs"), do: import_config("#{Mix.env()}.exs")
