defmodule Entry do
  # Enable pipeline-related features and conveniences like the `~>` operator.
  use Pipeline

  # Your first pipeline! Coming from Plug, `pipeline` works as kind of a hybrid
  # version of `init/1` and `call/2`. Instead of configuring the options for
  # your connection handler as `init/1` does for Plug, you configure the entire
  # processing sequence. The result of this function is a pipeline, _NOT_ a
  # connection object.

  # @spec Pipeline.t(Plug.Conn)
  def pipeline do
    empty
      ~> plug(Hello)
  end
end
