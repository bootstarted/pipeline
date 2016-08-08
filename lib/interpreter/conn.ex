defmodule Pipeline.Interpreter.Conn do
  @moduledoc """
  Run a pipeline with a given connection. This is the runtime equivalent of the
  pipeline compiler. It's still performant, but compiled code is always faster.
  The interpreter has one advantage in that you can use monadic bind to change
  the pipeline based on the value of the connection which is otherwise not
  possible in compilation, because the connection is not available.
  """

  alias Effects.Pure
  alias Effects.Effect
  alias Pipeline.Effects

  @doc """
  Derp.
  """
  defp effect({_, conn}, %Pure{value: value}) do
    {value, conn}
  end

  @doc """
  Derp.
  """
  defp effect({value, conn}, %Effect{
    effect: %Effects.Halt{} = entry,
    next: next,
  }) do
    {entry, conn}
  end

  @doc """
  Herp.
  """
  defp effect({value, conn}, %Effect{
    effect: %Effects.Match{patterns: patterns} = entry,
    next: next,
  }) do
    {_, pipeline} = patterns |> Enum.find(fn {guard, _} ->
      nil # TODO!
    end)
    nil |> effect(next.(entry))
  end

  @doc """
  kek.
  """
  defp effect(state, %Effect{
    effect: %Effects.Plug{plug: plug, options: options} = entry,
    next: next,
  }) do
    case apply(plug, :call, plug.init(options)) do
      # TODO Should this case be explicity checked for? It's fairly specific
      # to plug. Should we check the result of this function returns plugs?
      %{halted: true} = conn -> conn
      _ = conn -> state |> effect(next.(entry))
    end
  end

  def run(init, pipeline) do
    {_, conn} = {nil, init} |> effect(pipeline)
    conn
  end
end
