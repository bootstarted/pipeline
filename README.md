# pipeline

Monadic HTTP application composition for [plug] and friends.

![build status](http://img.shields.io/travis/metalabdesign/pipeline/master.svg?style=flat)
![coverage](http://img.shields.io/coveralls/metalabdesign/pipeline/master.svg?style=flat)
![license](http://img.shields.io/hexpm/l/pipeline.svg?style=flat)
![version](http://img.shields.io/hexpm/v/pipeline.svg?style=flat)
![downloads](http://img.shields.io/hexpm/dt/pipeline.svg?style=flat)

| Feature | Plug | Pipeline |
|------------|------------|------------|
| Composition | Static/Linear | Dynamic/Monadic |
| Guards | Fixed | Extensible |
| Error Handling | Global | Local |
| Control Flow | Dynamic | Static |
| Private Plugs | Yes | No |

Pipeline was created to address some of the limitations of Plug. Pipeline has equivalent features to Plug and remains fully interoperable with Plug itself – pipelines can both consume and act as plugs. Pipeline is powered by [effects].

Pipeline's long-term dream is to be officially incorporated into Plug in some fashion.

A simple example of using Pipeline:

```elixir
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
```

More examples can be found in the [/examples] folder.

## Usage

Pipeline provides several type constructors and the standard monadic operators for composing together all your plugs. After you've built your pipeline you feed it through an interpreter to produce a useful result.

**Type constructors** (build new pipelines):
 * `empty` - Create a new empty pipeline.
 * `halt` - Disregard all pipelines after this one.
 * `match` - Execute pipelines conditionally.
 * `plug` - Create a new pipeline that consists of just a single plug.
 * `error` - Create an error handler.

**Connection actions** (conveniences for `plug`):
 * `status` - Set response status code.
 * `body` - Set response body.
 * `set` - Set response header.
 * `send` - Send response.

**Monadic operations** (compose pipelines):
 * `~>>` or `bind` - Extend a pipeline based on a new pipeline generated from the previous one. In some ways this is like Elixir's `|>` operator.
 * `~>` or `then` - Extend a pipeline with another given pipeline. Just convenient shorthand for `~>>` without depending on the previous pipeline.
 * `fmap` or `flat_map` - TODO: Document this.
 * `ap` or `apply` - TODO: Document this.

**Interpreters** (apply actions):
 * `conn` - Apply a pipeline to a `Plug.Conn` object.
 * `compile` - Compile a pipeline into an Elixir AST.
 * `print` - Dump your pipeline to a string.
 * `test` - Use for testing your pipelines.
 * `transform` - Transform a pipeline (optimize/debug/etc.)

**Adapters**:
 * `cowboy` - Launch a pipeline-based app directly without Plug.

**DSLs**:
 * router - If you like `Plug.Router` this is for you!

### Constructors

Constructors allow you to create new effects for your pipeline.

Turning plugs into pipelines works exactly as the `plug` macro does.

```elixir
pipeline = plug(SomeModule, options)
```

Using halt:

```elixir
# my_other_plug will never be invoked.
plug(:my_plug) ~> halt ~> plug(:my_other_plug)
```

Similar in normal plug to:

```elixir
def my_other_plug(conn, options) do
  conn |> Plug.Conn.halt
end
```

Using match:

```elixir
match([
  {:some_matcher, plug(:plug_a)},
  {true, plug(:plug_b)}
])
```

### Monadic Operations

Pipeline provides all the standard monadic composition mechanisms to manipulate and combine pipelines including `fmap`, `apply` and `bind`. Although handy, knowledge of monads is not required to use these functions.

`fmap` allows you to rewrite whole pipelines.

```
pipeline = plug(Plug.Static) ~> plug(Plug.Parser)
pipeline |> fmap fn _ -> empty end
```

Using `then` allows you to easily chain those plugs together.

```elixir
plug(Plug.Static, to: "/", from: "/") ~> plug(Plug.Parser)
```

This is equivalent to normal Plug's:

```elixir
plug Plug.Static, to: "/", from: "/"
plug Plug.Parser
```

Using monadic `bind` allows altering the current pipeline based on the previous pipeline:

```elixir
pipelineA ~>> fn effects -> case effects |> Enum.contains(%Effects.Plug)
  True -> send(200, "Static plug!")
  _ -> empty
end ~> pipelineC
```


## Compatibility

Pipeline aims to exist peacefully and pragmatically in the current Plug ecosystem. Because of some fundamental implementation details within Plug some interoperability is less convenient or performant than it should be; some things Pipeline is capable of (like using anonymous functions) is downright incompatible with Plug and so if you want to be compatible with Plug you need to avoid using these features too.

There are two mechanisms providing Plug interoperability: `Pipeline.Plug.Export` and `Pipeline.Plug.Import`.

### Exports

Using exports is the least intrusive, most compatible but least performant interoperability mechanism. Using `Pipeline.Plug.Export` generates `init/1` and `call/2` for you from `pipeline/1`.

Plug works (roughly) by having consumers of your plug calling `init/1` and serializing the result into the AST of the consumer's module. This is designed to optimize the performance of `call/2` since you can do any expensive operations in `init/1`.

This is problematic for Pipeline because `init/1` _must_ return something compatible with `Macro.escape/1` – pipelines themselves are _not_ AST serializable and so it's not possible to make `init/1` return the pipeline itself.

Pipeline is fully capable of _compiling_ to an AST, but Plug provides no mechanism to hook into its compilation step and it's not possible to transparently alter module consumers, so this is where we're stuck at as far as providing Pipeline compatibility from within a provider module.

```elixir
defmodule MyPlug
  use Pipeline
  use Pipeline.Plug.Export

  # `pipeline/1` can be private here ensuring your module is indistinguishable
  # from any other plug.
  defp pipeline(path: path) do
    plug(Plug.Static, from: "./public", to: path)
  end

  # ----------------------------------------------------------------------------
  # Functions below are generated by `Pipeline.Plug.Export` and are included
  # merely for illustrative and documentative purposes.
  # ----------------------------------------------------------------------------
  def init(options) do
    options
  end

  def call(conn, options) do
    conn |> Pipeline.interpret(pipeline(options))
  end
end
```

This means you can pass a pipeline anywhere a plug is expected.

```elixir
defmodule App do
  use Pipeline

  # Generate Plug's `call/2` and `init/1` from `pipeline/1`.
  use Pipeline.Plug.Export

  def pipeline(_) do
    send(200, "Hello World.")
  end
end

defmodule Server do
  @moduledoc """
  Just a standard plug+cowboy server module consuming a Pipeline-based module.
  Because Pipeline generates a `call/2` and `init/1` from `pipeline/1` you can
  use pipelines everywhere you can use plugs. Fancy.
  """
  def start_link() do
    {:ok, _} = Plug.Adapters.Cowboy.http App, []
  end
end
```

### Imports

If you're willing to explicitly mark that your plug is a pipeline consumer, then there are much greater opportunities for optimization. Imports will scan your list of plugs and detect any of those which are pipelines. Those that are pipelines will be rewritten and compiled. As with exports, `pipeline/1` is the entrypoint.

```elixir
defmodule MyPlug
  use Pipeline

  # `pipeline/1` _must_ be public here, since it's to be called by the consumer,
  # after this module is compiled.
  def pipeline(path: path) do
    plug(Plug.Static, from: "./public", to: path)
  end
end

defmodule MyApp do
  use Pipeline.Plug.Import
  use Plug.Builder

  plug MyPipeline, path: "/public"
  plug SomeOtherRegularPlug
end
```


## Composition

Plug typically defines its configuration entirely statically – this is partly as a convenience and partly as a mechanism to provide compile-time optimizations. Unfortunately it makes it hard to combine plugs programatically.

By turning plugs into monads it's possible to do a lot more. Pipelines are, in a way, higher-order plugs.

```elixir
defmodule MyPlug do
  use Plug.Router

  # This method /foo is always present on this plug no matter what. The
  # mechanisms by which you create guards is fixed – you can only match against
  # the HTTP method, the verb and the path.
  get "/foo" do
    conn |> send_resp(200, "Hello World")
  end
end
```

```elixir
defmodule MyMessagePlug do
  use Pipeline

  # You can define your own private pipeline generating functions!
  def send_message(message) do
    send(200, message)
  end

  def pipeline({name, message}) do
    empty
      ~> match([{
        [Match.method(:get), Match.path("/" <> name)],
        send_message(message) ~> halt
      }])
  end
end

defmodule MyHelloPlug do
  use Pipeline

  def pipeline(name) do
    empty
      # Pipelines are actually composable! One pipeline can incorporate another
      # with values defined at configuration time – something not possible with
      # vanilla plugs.
      ~> MyMessagePlug.pipeline({name, "Hello " <> name})
      ~> MyMessagePlug.send_message("????")
  end
end

defmodule MyApp do
  use Plug.Builder
  # Using this behavior to define routes that depend on these parameters is
  # something unique to pipelines.
  plug MyHelloPlug, "bob"
  plug MyHelloPlug, "fred"
end
```

Fancy.

### Guards

The guards in plug come from using `Plug.Router`.

```elixir
defmodule MyApp do
  # The only possible matching tuple in plug.
  get "/", host: "foo.bar." do
    conn |> send_resp(200, "is foo")
  end

  get "/" do
    conn |> send_resp(200, "not foo")
  end
end
```

Pipeline's guards are built by composing pipelines and predicates together, similar to plugs `forward:` option

```elixir
defmodule MyApp do
  use Pipeline

  def pipeline(_) do
    match([
      {host("foo.bar."), send(200, "is foo")}
      {true, send(200, "not foo")},
    ])
  end
end
```

Most importantly, however, pipeline allows for your own guards as first class citizens.

## Error Handling

Error handling in Pipeline works akin to that of Promises.

```elixir
# errors some a and b will be processed, but not from c
a ~> b ~> error(...) ~> c

```

This is in contrast to Plug's:

```elixir
defp handle_errors(foo, bar) do

end
```

## Transforming

Because pipeline is backed by [effects], one only needs to change the pipeline interpreter to entirely change how pipelines are processed.

### Optimization

Plug makes extensive use of Elixir's macro facility to ensure everything runs as fast as possible – pipeline is no different.

## Testing

Using [effects] means that testing pipelines is straightforward. Instead of using the connection interpreter or the compilation interpreter you can use one for testing that doesn't actually do anything.

TODO: Show how.

[effects]: https://github.com/metalabdesign/effects
[plug]: https://github.com/elixir-lang/plug
