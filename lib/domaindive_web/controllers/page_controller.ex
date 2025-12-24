defmodule DomaindiveWeb.PageController do
  use DomaindiveWeb, :controller
  alias Domaindive.Analysis
  alias Domaindive.Analysis.WhoisParser

  def home(conn, _params) do
    render(conn, :home)
  end

  def analysis(conn, %{"domain" => domain} = params) do
    force_refresh = Map.get(params, "refresh") == "true"

    case Analysis.get_or_create_analysis(domain, force_refresh) do
      {:ok, domain_analysis, cache_status} ->
        whois_info = WhoisParser.parse(domain_analysis.whois_data)
        dns_records = decode_json(domain_analysis.dns_records, %{})
        nameservers = decode_json(domain_analysis.nameservers, [])
        ssl_info = decode_json(domain_analysis.ssl_info, %{available: false})
        http_response = decode_json(domain_analysis.http_response, %{})
        geolocation = decode_json(domain_analysis.geolocation, %{})

        seconds_until_refresh = Analysis.seconds_until_refresh(domain_analysis)

        render(conn, :analysis,
          domain_analysis: domain_analysis,
          whois_info: whois_info,
          dns_records: dns_records,
          nameservers: nameservers,
          ssl_info: ssl_info,
          http_response: http_response,
          geolocation: geolocation,
          cache_status: cache_status,
          seconds_until_refresh: seconds_until_refresh
        )

      {:error, changeset} ->
        error_message =
          case changeset.errors[:address] do
            {msg, _} -> msg
            _ -> "Invalid domain name"
          end

        conn
        |> put_flash(:error, error_message)
        |> redirect(to: ~p"/")
    end
  end

  defp decode_json(nil, default), do: default

  defp decode_json(json_string, default) do
    case Jason.decode(json_string, keys: :atoms) do
      {:ok, data} -> data
      {:error, _} -> default
    end
  end
end
