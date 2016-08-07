defmodule Pipeline.Adapter.Cowboy do
  @moduledoc """
  Pretty much built off Plug's adapter, but simpler and supports the static
  optimization mechanisms provided by pipeline.

  TODO: Add more options to be at feature-parity with Plug's adapter.
  """

  alias Pipeline.Interpreter.Compiler

  @doc """
  Make sure cowboy is running.
  """
  def ensure_cowboy do
    case Application.ensure_all_started(:cowboy) do
      {:ok, _} ->
        :ok
      {:error, {:cowboy, _}} ->
        raise "could not start the cowboy application. Please ensure it is" <>
          "listed as a dependency both in deps and application in your mix.exs"
    end
  end

  defmacro __before_compile__(env) do
    pipeline = Module.get_attribute(env.module, :pipeline)
    # The variable used here has to be passed around in the same module
    # everywhere – there can't be a `conn` defined here and another defined in
    # the compiler because they have different contexts.
    conn = quote do: conn
    # Generate the compiled version of the application pipeline.
    # TODO: Consider `pipeline ~> plug(maybe_send, __MODULE__)` as an option
    # instead of hardcoding `maybe_send`?
    body = conn |> Compiler.compile(pipeline)
    # Inject it into the module as pipeline/1.
    quote do: def pipeline(unquote(conn)), do: unquote(body)
  end

  defmacro __using__(opts) do
    quote do
      # Default cowboy reference name.
      @ref Module.concat(__MODULE__, "_pipeline")

      # Default number of cowboy acceptors.
      @acceptors 100

      # Default structure for the connection object.
      @connection Plug.Adapters.Cowboy.Conn

      # ??? Copied from plug lol.
      @already_sent {:plug_conn, :sent}

      # Default pipeline to use for processing connections.
      @pipeline unquote(Keyword.get(opts, :pipeline))

      # Default listening protocol.
      @protocol :http

      # Default listening port.
      @port 0

      # Actually compile the pipeline into something useable.
      @before_compile unquote(__MODULE__)

      @doc """

      """
      def start_link(options) do
        {:ok, _} = run(options)
      end

      @doc """

      """
      def init({transport, :http}, req, _) when transport in [:tcp, :ssl] do
        {:upgrade, :protocol, __MODULE__, req, transport}
      end

      @doc """

      """
      def upgrade(req, env, __MODULE__, transport) do
        # Generate the Plug connection object from the request.
        conn = @connection.conn(req, transport)
        try do
          %{adapter: {@connection, req}} = conn
          # Send the connection to be processed by the pipeline.
          |> pipeline
          # Do any last minute things.
          |> maybe_send
          # Return the result back to cowboy.
          {:ok, req, [{:result, :ok} | env]}
        catch
          :error, value ->
            stack = System.stacktrace()
            exception = Exception.normalize(:error, value, stack)
            reason = {{exception, stack}, conn}
            terminate(reason, req, stack)
          :throw, value ->
            stack = System.stacktrace()
            reason = {{{:nocatch, value}, stack}, conn}
            terminate(reason, req, stack)
          :exit, value ->
            stack = System.stacktrace()
            reason = {value, conn}
            terminate(reason, req, stack)
        after
          receive do
            @already_sent -> :ok
          after
            0 -> :ok
          end
        end
      end

      defp maybe_send(%Plug.Conn{state: :unset}) do
        raise Plug.Conn.NotSentError
      end
      defp maybe_send(%Plug.Conn{state: :set} = conn) do
        Plug.Conn.send_resp(conn)
      end
      defp maybe_send(%Plug.Conn{} = conn) do
        conn
      end
      defp maybe_send(other) do
        raise "Cowboy adapter expected #{__MODULE__} to return Plug.Conn but got: #{inspect other}"
      end

      defp terminate(reason, req, stack) do
        :cowboy_req.maybe_reply(stack, req)
        exit(reason)
      end

      defp dispatch() do
        :cowboy_router.compile([{:_, [
          {:_, __MODULE__, []},
        ]}])
      end

      @doc """
      Bootstart the cowboy application.
      """
      defp run(options \\ []) do
        ref = options |> Keyword.get(:ref, @ref)
        acceptors = options |> Keyword.get(:acceptors, @acceptors)
        scheme = options |> Keyword.get(:protocol, @protocol)
        port = options |> Keyword.get(:port, @port)

        Pipeline.Adapter.Cowboy.ensure_cowboy
        apply(:cowboy, :"start_#{scheme}", [
          ref,
          acceptors,
          [port: port],
          [env: [dispatch: dispatch]],
        ])
      end
    end
  end
end
