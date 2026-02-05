defmodule RevenueCat.Client.Req do
  @moduledoc false

  @behaviour RevenueCat.Client

  @doc """
  Execute a request using Req and normalize the response.
  """
  @impl true
  def do_request(opts) do
    case Req.request(opts) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
