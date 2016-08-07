defmodule Pipeline do
  @moduledoc """
  Pipeline is a monad-based alternative to Plug's builder and router. It offers
  much of the same functionality.

  This module can be `use`-d into a module in order to build a pipeline:

  ```elixir
  defmodule MyApp do
    use Pipeline

    def hello(conn, opts) do
      Plug.Conn.send_resp(conn, 200, body)
    end

    def pipeline(options) do
      empty
        ~> plug(Plug.Logger)
        ~> plug(:hello)
    end
  end
  ```
  """

  use Effects

  # ----------------------------------------------------------
  # Actions
  # ----------------------------------------------------------
  defmodule Effects do
    defmodule Plug do
      @type t :: %Plug{plug: atom, options: term}
      defstruct [:plug, :options]
    end

    defmodule Match do
      @type t :: %Match{patterns: term}
      defstruct [:patterns]
    end

    defmodule Error do
      @type t :: %Error{handler: term}
      defstruct [:handler]
    end

    defmodule Halt do
      @type t :: %Halt{}
      defstruct []
    end
  end

  # Our effects are not really extensible since open-union types are not
  # possible here :(
  @type e :: Effects.Plug.t | Effects.Match.t | Effects.Halt.t
  @type t :: Free.t(e)

  # ----------------------------------------------------------
  # Effect Creators
  # ----------------------------------------------------------
  defeffect plug(_plug, _options, _guards) do
    raise ArgumentError, message: "Guards not supported by Pipeline."
  end

  @doc """
  Use a plug.
  """
  defeffect plug(plug, options \\ nil) do
    %Effects.Plug{plug: plug, options: options}
  end

  @doc """
  Basically a structural `cond` or `case` statement.
  """
  defeffect match(patterns) do
    %Effects.Match{patterns: patterns}
  end

  @doc """
  Handle some errors.
  """
  defeffect error(handler) do
    %Effects.Error{handler: handler}
  end

  @doc """
  Halt the pipeline.
  """
  defeffect halt() do
    %Effects.Halt{}
  end

  def match(predicate, consequent) do
    match([{predicate, consequent}])
  end

  def match(predicate, consequent, alternate) do
    match([{predicate, consequent}, {true, alternate}])
  end

  @doc """
  The "unit". Mainly just useful for chaining off of so things don't look weird.
  You can do things like: `empty ~> foo ~> bar`.
  """
  def empty() do
    pure(nil)
  end

  @doc """
  The ~>> operator.
  """
  defdelegate ~>>, to: Free, as: ~>>

  @doc """
  The ~> operator.
  """
  defdelegate ~>, to: Free, as: ~>

  @doc """

  """
  defdelegate fmap, to: Free, as: fmap

  @doc """

  """
  defdelegate ap, to: Free, as: ap

  # ----------------------------------------------------------
  # Other
  # ----------------------------------------------------------
  defmacro __using__(opts) do
    quote do
      # Automatic shorthand for the various pipeline creators.
      import Pipeline

      # Quick access to match predicates.
      alias Pipeline.Match
    end
  end
end
