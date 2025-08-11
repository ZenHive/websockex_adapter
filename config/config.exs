import Config

export_dir =
  if Mix.env() == :test do
    System.tmp_dir!() <> "/zen_websocket_test_exports"
  else
    "exports/"
  end

# config :zen_websocket, SlipstreamClient, uri: "ws://test.deribit.com:8080/api/v2/"
config :zen_websocket, Deribit,
  client_id: System.fetch_env!("DERIBIT_CLIENT_ID"),
  client_secret: System.fetch_env!("DERIBIT_CLIENT_SECRET")

config :zen_websocket, export_dir: export_dir
