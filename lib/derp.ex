defmodule Derp do
  import Pipeline

  @doc """
  Set the HTTP status code of the response.
  """
  def status(value) when is_integer(value) do
    plug(&Plug.Conn.put_status/2, value)
  end

  @doc """
  Set the response body.
  """
  def body(content) do
    plug(&Pipeline.Util.put_resp/2, content)
  end

  @doc """
  Set a response header.
  """
  def put(header, value) do
    plug(&Plug.Conn.put_resp_header(&1, header, value))
  end

  @doc """
  Send the response.
  """
  def send() do
    plug(&Plug.Conn.send_resp/1)
  end
end
