defmodule Test.Pipeline.Adapter.Cowboy do
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
    def pipeline() do
      empty ~> plug(HelloPlug)
    end
  end

  defmodule SampleServer do
    @connection Plug.Adapters.Cowboy.Conn
    use Pipeline.Adapter.Cowboy, pipeline: SamplePipeline.pipeline
  end

  describe "pipeline/adapter/cowboy" do
    it "should work" do
      {:ok, pid} = SampleServer.start_link [port: 4000]
      %{
        status_code: status,
        body: body,
      } = HTTPoison.get! "http://localhost:4000/"
      Process.exit(pid, :normal)
      expect status |> to(eq 200)
      expect body |> to(eq "Hello world.")
    end
  end

end
