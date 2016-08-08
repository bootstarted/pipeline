defmodule Test.Pipeline.Plug.Import do
  use ESpec
  use Plug.Test

  import Pipeline

  defmodule HelloPlug do
    def init(_) do
      nil
    end
    def call(conn, _) do
      conn
      |> Plug.Conn.put_resp_content_type("text/plain")
      |> Plug.Conn.send_resp(200, "Hello world.")
    end
  end

  defmodule SamplePipeline do
    def pipeline(options) do
      empty ~> plug(HelloPlug)
    end
  end

  defmodule PipelineConsumer do
    # Needed for being able to call `plug some_pipeline`.
    use Pipeline.Plug.Import
    # Needed for using the `plug` macro.
    use Plug.Builder

    # Access a pipeline as if it were a plug!
    Plug.Builder.plug SamplePipeline
  end

  describe "pipeline/plug/import" do
    it "should work" do
      # Create a fake connection object.
      conn = conn(:get, "/hello")
      # Invoke `PipelineConsumer` as a normal plug.
      conn = PipelineConsumer.call(conn, PipelineConsumer.init([]))
      # Ensure the correct response.
      expect conn.state |> to(eq :sent)
      expect conn.status |> to(eq 200)
      expect conn.resp_body |> to(eq "Hello world.")
    end
  end

end
