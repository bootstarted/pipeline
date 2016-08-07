defmodule Pipeline.Plug.Export do
  alias Pipeline.Interpreter.Conn
  @callback pipeline(any) :: Free.t
  defmacro __using__(opts) do
    quote do
      # Pipelines are also plugs!
      @behaviour Plug
      @behaviour Pipeline.Plug.Export

      @doc """

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
      works, but you need to `use Pipeline.Plug` in your plug-based module.
      """
      def call(conn, options) do
        conn |> Conn.run(pipeline(options))
      end
    end
  end
end
