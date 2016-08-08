defmodule Pipeline.Plug.Import do
  @moduledoc """
  This module lets you take advantage of Plug's static compilation mechanism
  from within Pipeline. When you have a module that invokes `plug Pipeline`
  this pre-compilation hook generates a private function within that module
  representing the invocation of that pipeline and then replaces the plug call
  with the generated private function.

  Unfortunately there is currently no automatic mechanism for doing this, so
  you're stuck with having to `use` this module to gain its beneficial effects.

  **IMPORTANT**: You must `use` this module _before_ you `use` anything from
  Plug, since it modifies the internal list of plugs.
  """

  alias Pipeline.Interpreter.Compiler

  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    # Get the list of existing plugs. This attribute is previously registered
    # by `Plug.Builder` and appended to via the `plug` macro.
    plugs = Module.get_attribute(env.module, :plugs)

    # The variable used here has to be passed around in the same module
    # everywhere – there can't be a `conn` defined here and another defined in
    # the compiler because they have different contexts.
    conn = quote do: conn

    # Find all plugs that are pipelines and compile those pipelines. Results
    # in a new list of plugs that contain the quoted compiled pipeline for
    # those entries which are pipelines.
    updates = plugs
    |> Enum.with_index()
    |> Enum.map(fn {{plug, options, _} = entry, index} ->
      case Keyword.get(plug.__info__(:functions), :pipeline) do
        1 ->
          # Generate a unique name for the internal function.
          # TODO: Consider a more bullet-proof mechanism than this?
          uniq = String.to_atom("__pipeline_int_" <> Integer.to_string(index))
          {
            {uniq, nil, true},
            quote do
              defp unquote(uniq)(conn, _) do
                unquote(
                  conn |> Compiler.compile(plug.pipeline(options))
                )
              end
            end,
          }
        _ -> {entry, nil}
      end
    end)

    # Rewrite the list of plugs with our new generated function.
    Module.delete_attribute(env.module, :plugs)
    updates
    |> Enum.map(fn {plug, _} -> plug end)
    |> Enum.each(&Module.put_attribute(env.module, :plugs, &1))

    # Inject the generated functions into the consumer module.
    updates
    |> Enum.map(fn {_, q} -> q end)
    |> Enum.filter(fn x -> x end)

  end
end
