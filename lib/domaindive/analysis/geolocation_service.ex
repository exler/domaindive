defmodule Domaindive.Analysis.GeolocationService do
  @moduledoc """
  Service for getting geolocation information for an IP address.
  Uses the free ip-api.com service.
  """

  @api_url "http://ip-api.com/json/"

  @doc """
  Fetches geolocation data for an IP address.

  Returns `{:ok, location_data}` on success.
  """
  def fetch_location(ip_address) do
    case Req.get("#{@api_url}#{ip_address}") do
      {:ok, %{status: 200, body: body}} ->
        parse_response(body)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_response(%{"status" => "success"} = data) do
    result = %{
      ip: data["query"],
      country: data["country"],
      region: data["regionName"],
      city: data["city"],
      zip: data["zip"],
      lat: data["lat"],
      lon: data["lon"],
      timezone: data["timezone"],
      isp: data["isp"],
      org: data["org"],
      as: data["as"]
    }

    {:ok, result}
  end

  defp parse_response(%{"status" => "fail", "message" => message}) do
    {:error, message}
  end

  defp parse_response(_) do
    {:error, :invalid_response}
  end
end
