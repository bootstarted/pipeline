defmodule Pipeline.Util do
  @doc """
  Set the contents of the response body. Unfortunately Plug has no function
  to do this natively (you're always forced to set the status too) so we have
  our own here.
  """
  def put_resp(conn, content) do
    %{conn | resp_body: content, state: :set}
  end
end
