defmodule Hello do
  def init(_) do
    nil
  end
  def call(conn, _) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, "Hello world")
  end
end
