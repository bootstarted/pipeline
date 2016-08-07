defmodule Pipeline.Example.Basic do
  defmodule Entry do
    # Enable pipeline-related features and conveniences like the `~>` operator.
    use Pipeline

    # Your first pipeline! Coming from Plug, `pipeline` works as kind of a hybrid
    # version of `init/1` and `call/2`. Instead of configuring the options for
    # your connection handler as `init/1` does for Plug, you configure the entire
    # processing sequence.
    def pipeline do
      send(200, "Hello World.")
    end
  end

  defmodule Server do
    @moduledoc """
    Using Pipeline's HTTP adapter instead of Plug's gives a few extra goodies.
    They're very similar under the hood, however. This setup will produce a
    worker process that you can feed into your application supervisor.
    """
    use Pipeline.Adapter.Cowboy, pipeline: Entry.pipeline
  end

  defmodule MyApplication do
    use Application

    # See http://elixir-lang.org/docs/stable/elixir/Application.html
    # for more information on OTP Applications
    def start(_type, _args) do
      import Supervisor.Spec, warn: false

      children = [
        # Start pipeline-based server.
        worker(Server, [[port: 4000]]),
      ]

      # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
      # for other strategies and supported options
      opts = [strategy: :one_for_one, name: MyApplication.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
end
