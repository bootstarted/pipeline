defmodule Pipeline.Plug.Export do
  @moduledoc """
  TODO: Write me.
  """

  # Use the pipeline connection interpreter.
  alias Pipeline.Interpreter.Conn

  # Anyone that has our behaviour must implement `pipeline/1` as a function that
  # generates a pipeline from some given options.
  @callback pipeline(any) :: any

  defmacro __using__(opts) do
    quote do
      # Pipelines are also plugs! Implementing this behaviour means the module
      # must have init/1 and call/2, both of which are provided by this macro.
      @behaviour Plug

      # In order to generate `init/1` and `call/2` we need access to the
      # generated pipeline, and thus some function must _generate_ that
      # pipeline. We define `pipeline/1` as the function that does this, with
      # its first argument being the argument to `init/1` (that is to say the
      # configuration options for the plug interface define the configuration
      # options for the pipeline).
      @behaviour Pipeline.Plug.Export

      @doc """
      Setup the pipeline based on the given configuration options. The result
      of this is then saved by Plug in your application and fed to `call/2` as
      the second argument.
      """
      def init(options) do
        options
      end

      @doc """
      Run the connection through the configured pipeline. Note that this is
      not nearly as performant as a compiled version, but it's the way it has
      to be for plug. Plug's `init` has to return a representation that is
      serializable (no anonymous functions) because its results get passed to
      `Macro.escape` eventually. If Plug were to call `init` when the program
      started (like via module_loaded hook) all of this would be solved. Alas,
      here we are.

      Note that using Pipeline this way is not necessary; you can use Pipeline's
      interop pre-compilation hook and compile your pipeline the same way Plug
      works, but you need to `use Pipeline.Plug.Import` in your plug-based
      module.
      """
      def call(conn, options) do
        conn |> Conn.run(pipeline(options))
      end
    end
  end
end
