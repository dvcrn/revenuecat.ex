defmodule RevenueCat.Client do
  @moduledoc """
  HTTP client adapter interface for RevenueCat requests.
  """

  @rc_base_url "https://api.revenuecat.com"
  @timeout_ms 15_000

  @type request_opts :: keyword()
  @type response :: {:ok, binary()} | {:error, term()}

  @callback do_request(request_opts()) :: response()

  @doc """
  Dispatch a fully-formed request to the configured adapter.
  """
  @spec do_request(request_opts()) :: response()
  def do_request(opts) when is_list(opts) do
    adapter().do_request(opts)
  end

  @doc """
  Build and dispatch a request with RevenueCat headers and base options.
  """
  @spec do_request(atom(), String.t(), request_opts()) :: response()
  def do_request(method, path, opts \\ [])
      when is_atom(method) and is_binary(path) and is_list(opts) do
    {headers, opts} = Keyword.pop(opts, :headers, [])
    {api_key, opts} = Keyword.pop(opts, :api_key, nil)
    {base_url, opts} = Keyword.pop(opts, :base_url, nil)

    with {:ok, api_key} <- api_key(api_key) do
      request_opts =
        base_opts()
        |> Keyword.merge(opts)
        |> Keyword.merge(
          method: method,
          url: build_url(base_url, path),
          headers: default_headers(api_key) ++ headers
        )

      do_request(request_opts)
    end
  end

  defp api_key(nil) do
    api_key = Application.get_env(:revenuecat, :api_key) || System.get_env("REVENUECAT_API_KEY")

    if is_binary(api_key) and api_key != "" do
      {:ok, api_key}
    else
      {:error, :missing_api_key}
    end
  end

  defp api_key(api_key) when is_binary(api_key) and api_key != "", do: {:ok, api_key}
  defp api_key(_), do: {:error, :missing_api_key}

  defp build_url(nil, path) do
    base_url =
      Application.get_env(:revenuecat, :base_url) || System.get_env("REVENUECAT_BASE_URL")

    (base_url || @rc_base_url) <> path
  end

  defp build_url(base_url, path) when is_binary(base_url) and base_url != "" do
    base_url <> path
  end

  defp build_url(_, path), do: build_url(nil, path)

  defp default_headers(api_key) do
    [
      {"authorization", "Bearer " <> api_key},
      {"accept", "application/json"}
    ]
  end

  defp base_opts do
    [
      connect_options: [timeout: @timeout_ms],
      receive_timeout: @timeout_ms,
      decode_body: false
    ]
  end

  defp adapter do
    Application.get_env(:revenuecat, :client_adapter, RevenueCat.Client.Req)
  end
end
