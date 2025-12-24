defmodule Domaindive.Analysis.HttpService do
  @moduledoc """
  Service for fetching HTTP response headers from a domain.
  """

  @doc """
  Fetches HTTP response headers for a given domain.

  Returns `{:ok, headers}` on success.
  """
  def fetch_headers(domain) do
    url = "https://#{domain}"

    case Req.head(url, redirect: false, connect_options: [timeout: 10_000]) do
      {:ok, %{status: status, headers: headers}} when status in 200..399 ->
        {:ok, %{status: status, headers: normalize_headers(headers)}}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        fallback_to_http(domain, reason)
    end
  end

  defp fallback_to_http(domain, _https_error) do
    url = "http://#{domain}"

    case Req.head(url, redirect: false, connect_options: [timeout: 10_000]) do
      {:ok, %{status: status, headers: headers}} when status in 200..399 ->
        {:ok, %{status: status, headers: normalize_headers(headers)}}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize_headers(headers) do
    headers
    |> Enum.map(fn {key, value} ->
      value_str =
        case value do
          list when is_list(list) -> Enum.join(list, ", ")
          str -> to_string(str)
        end

      {key, value_str}
    end)
    |> Map.new()
  end
end
