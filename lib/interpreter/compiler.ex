defmodule Pipeline.Interpreter.Compiler do
  @moduledoc """
  Convert a pipeline into an elixir AST.

  Because the plug chain is stored as essentially an abstract syntax tree we
  can perform any number of optimizations on it.
  """

  import Effects, only: [queue_apply: 2]
  alias Effects.Pure
  alias Effects.Effect
  alias Pipeline.Effects

  defp convert(target, plug, options) when is_atom(plug) do
    case Atom.to_char_list(plug) do
      'Elixir.' ++ _ -> quote do
        unquote(plug).call(
          unquote(target),
          unquote(Macro.escape(plug.init(options)))
        )
      end
      _ -> quote do
        unquote(plug)(unquote(target), unquote(Macro.escape(options)))
      end
    end
  end

  defp convert(target, plug, options) when is_function(plug) do
    raise "TODO: Make this work."
  end

  @doc """
  Derp.
  """
  defp effect({_, compilation}, %Pure{value: value}) do
    {value, compilation}
  end

  @doc """
  Derp.
  """
  defp effect({value, compilation}, %Effect{
    effect: %Effects.Halt{} = entry,
  }) do
    {entry, compilation}
  end

  @doc """
  Herp.
  """
  defp effect(state, %Effect{
    effect: %Effects.Match{patterns: patterns} = entry,
    next: next,
  }) do
    {value, compilation} = state |> effect(queue_apply(next, entry))
    {entry, {:cond, [], [[do: patterns |> Enum.map(fn {guard, pipeline} ->
      {:->, [], [[true], compilation |> compile(pipeline)]}
    end)]]}}
  end

  @doc """
  wop.
  """
  defp effect(state, %Effect{
    effect: %Effects.Error{handler: handler} = entry,
    next: next,
  }) do
    foo = quote do: x
    {value, compilation} = state
    {_, bar} = {entry, foo} |> compile(handler)
    {value, quote do
      try do
        unquote(compilation)
      catch
        unquote(foo) -> unquote(bar)
      end
    end} |> effect(queue_apply(next, entry))
  end

  @doc """
  kek.
  """
  defp effect(state, %Effect{
    effect: %Effects.Plug{plug: plug, options: options} = entry,
    next: next,
  }) do
    {value, target} = state
    foo = quote do: x
    {_, compilation} = {value, foo} |> effect(queue_apply(next, entry))
    {entry, quote do
      case unquote(convert(target, plug, options)) do
        %Plug.Conn{halted: true} = x -> x
        %Plug.Conn{} = unquote(foo) -> unquote(compilation)
        _ -> raise unquote("Must return a plug connection.")
      end
    end}
  end

  defp effect(_, effect) do
    raise "Expected valid pipeline effect object, but got #{inspect effect}."
  end

  @doc """

  """
  def compile(init, pipeline) do
    {_, compilation} = {nil, init} |> effect(pipeline)
    compilation
  end
end
