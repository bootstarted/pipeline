defmodule Pipeline.Router do
  @moduledoc """
  Just like Plug's Router!

  Generates pipeline/0 and pipeline/1 for your module.
  """

  defmacro __using__(opts) do
    quote do
      # Collect list of plugs.
      Module.register_attribute(__MODULE__, :plugs, accumulate: true)
      # Convert plugs into pipeline/0.
      @before_compile unquote(__MODULE__)

      @doc """
      Provides equivalent to Plug's plug macro that can be used in module
      definitions.
      """
      defmacro plug(name, opts \\ []) do
        quote do
          @plugs {unquote(name), unquote(opts)}
        end
      end
    end
  end

  @doc """

  """
  defmacro __before_compile__(env) do
    parts = Keyword.get(env.module, :plugs)
    base = quote do: Pipeline.empty
    code = parts |> Enum.reduce(base, fn ({name, opts}, prev) ->
      quote do
        unquote(prev) ~> Pipeline.plug(unquote(name), unquote(opts))
      end
    end)
    quote do
      # Generate pipeline/0.
      def pipeline do
        unquote(code)
      end

      # Generate pipeline/1 as an alias to pipeline/0. Useful for consumption
      # as a plug because plugs are always allowed to pass options and when
      # using this DSL the options are totally irrelevent.
      def pipeline(_) do
        pipeline
      end
    end
  end


end
