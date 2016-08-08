defmodule Pipeline.Plug.Send do
  def init(_) do
    nil
  end

  def call(%Plug.Conn{state: :unset}, _) do
    raise Plug.Conn.NotSentError
  end
  def call(%Plug.Conn{state: :set} = conn, _) do
    Plug.Conn.send_resp(conn)
  end
  def call(%Plug.Conn{} = conn, _) do
    conn
  end
  def call(other, _) do
    raise "Expected Plug.Conn but got: #{inspect other}"
  end
end
