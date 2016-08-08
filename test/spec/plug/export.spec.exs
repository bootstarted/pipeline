defmodule Test.Pipeline.Plug.Export do
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

  defmodule SamplePlug do
    use Pipeline.Plug.Export
    def pipeline(options) do
      empty ~> plug(HelloPlug)
    end
  end

  describe "pipeline/plug/export" do
    it "should work" do
      # Create a fake connection object.
      conn = conn(:get, "/hello")
      # Invoke `SamplePlug` as a normal plug.
      conn = SamplePlug.call(conn, SamplePlug.init([]))
      # Ensure the correct response.
      expect conn.state |> to(eq :sent)
      expect conn.status |> to(eq 200)
      expect conn.resp_body |> to(eq "Hello world.")
    end
  end

end
