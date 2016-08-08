defmodule Pipeline.Interpreter.Transform do
  @moduledoc """
  Alter pipelines. Basically just a free interpreter whose state is also a
  pipeline being built up using the transformed existing pipeline.
  """

  import Pipeline

  defmodule Identity do
    @moduledoc """
    A transform that just returns the existing pipeline. This is mainly useful
    in that other transforms can extend this one and then only need to add
    effect handlers for the things they are interested in.
    """

    @doc """

    """
    def effect(pipeline, %Effects.Effect{
      effect: effect,
      next: next,
    }) do
      nil |> effect(next.(nil))
    end

    @doc """

    """
    def effect(pipeline, %Effects.Pure{
      value: value,
    }) do
      nil
    end
  end

  defmodule DebugPipeline do
    @moduledoc """
    Insert debug logging statements between all parts of a pipeline.
    """

    def log(%Pipeline.Effects.Plug{plug: plug, options: options}) do

    end

    def effect(pipeline, %Effects.Effect{
      effect: effect,
      next: next,
    }) do
      # pipeline ~> log(effect) ~> effect(next.())
    end
  end

  defmodule PlugToPipeline do
    @moduledoc """
    Turn `plug(SomePlug, options)` into `SomePlug.pipeline(options)` for plugs
    which are pipelines. This is essentially an optimization pass resulting in less overhead.
    """
    def effect(pipeline, %Effects.Effect{
      effect: %Pipeline.Effects.Plug{plug: plug, options: options} = entry,
      next: next,
    }) do
      case function_exported?(plug, :pipeline, 1) do
        true -> pipeline ~> apply(plug, :pipeline, [options]) ~>> next
        _ -> pipeline ~> entry ~>> next
      end
    end
  end

  defmodule MatchFolding do
    @moduledoc """
    Turn match([x ~> halt]) ~> match([y ~> halt]) into
    match([x ~> halt, y ~> halt])
    """
  end

  defmodule ActionFusion do
    @moduledoc """
    Fuse together several component actions in sequence to a single function.
    e.g. Convert `status(200) ~> body("Hello World.") ~> send()` into a single
    `plug(fn conn -> conn |> send_resp(200, "Hello World") end)`.

    """
  end
end
