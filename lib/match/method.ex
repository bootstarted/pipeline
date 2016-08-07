defmodule Pipeline.Match.Method do



  @doc """
  Converts a given method to its connection representation.

  The request method is stored in the `Plug.Conn` struct as an uppercase string
  (like `"GET"` or `"POST"`). This function converts `method` to that
  representation.

  ## Examples
      iex> Plug.Router.Utils.normalize_method(:get)
      "GET"
  """
  def normalize(method) do
    method |> to_string |> String.upcase
  end
end
