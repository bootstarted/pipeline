defmodule Server do
  @moduledoc """
  Using Pipeline's HTTP adapter instead of Plug's gives a few extra goodies.
  They're very similar under the hood, however. This setup will produce a
  worker process that you can feed into your application supervisor.
  """

  # For `empty`, `~>`, and `plug`.
  import Pipeline

  # Even though we're _not_ using Plug's adapter, we're still using Plug's
  # connection object to pass around between stages. This ensures we can use
  # other plugs because that's the kind of object they will expect. If one
  # wanted to not rely on Plug at all, a different kind of connection object
  # could be provided.
  @connection Plug.Adapters.Cowboy.Conn

  # Generate all the necessary boilerplate.
  use Pipeline.Adapter.Cowboy,
    pipeline: empty
      ~> Entry.pipeline
      ~> plug(Pipeline.Plug.Send)
end
