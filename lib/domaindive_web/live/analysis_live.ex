defmodule DomaindiveWeb.AnalysisLive do
  use DomaindiveWeb, :live_view
  alias Domaindive.Analysis
  alias Domaindive.Analysis.WhoisParser

  @impl true
  def mount(%{"domain" => domain} = params, _session, socket) do
    force_refresh = Map.get(params, "refresh") == "true"

    socket =
      socket
      |> assign(:domain, domain)
      |> assign(:loading, true)
      |> assign(:error, nil)

    if connected?(socket) do
      send(self(), {:fetch_analysis, domain, force_refresh})
    end

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: ~p"/")}
  end

  @impl true
  def handle_info({:fetch_analysis, domain, force_refresh}, socket) do
    case Analysis.get_or_create_analysis(domain, force_refresh) do
      {:ok, domain_analysis, cache_status} ->
        whois_info = WhoisParser.parse(domain_analysis.whois_data)
        dns_records = decode_json(domain_analysis.dns_records, %{})
        nameservers = decode_json(domain_analysis.nameservers, [])
        ssl_info = decode_json(domain_analysis.ssl_info, %{available: false})
        http_response = decode_json(domain_analysis.http_response, %{})
        geolocation = decode_json(domain_analysis.geolocation, %{})

        seconds_until_refresh = Analysis.seconds_until_refresh(domain_analysis)

        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:domain_analysis, domain_analysis)
         |> assign(:whois_info, whois_info)
         |> assign(:dns_records, dns_records)
         |> assign(:nameservers, nameservers)
         |> assign(:ssl_info, ssl_info)
         |> assign(:http_response, http_response)
         |> assign(:geolocation, geolocation)
         |> assign(:cache_status, cache_status)
         |> assign(:seconds_until_refresh, seconds_until_refresh)}

      {:error, changeset} ->
        error_message =
          case changeset.errors[:address] do
            {msg, _} -> msg
            _ -> "Invalid domain name"
          end

        {:noreply,
         socket
         |> assign(:loading, false)
         |> assign(:error, error_message)}
    end
  end

  defp decode_json(nil, default), do: default

  defp decode_json(json_string, default) do
    case Jason.decode(json_string, keys: :atoms) do
      {:ok, data} -> data
      {:error, _} -> default
    end
  end

  defp format_date(nil), do: "N/A"

  defp format_date(date_string) when is_binary(date_string) do
    date_string
    |> String.split("T")
    |> List.first()
  end

  defp flatten_dns_records(dns_records) when is_map(dns_records) do
    dns_records
    |> Enum.flat_map(fn {type, records} ->
      if is_list(records) do
        Enum.map(records, fn record ->
          Map.put(record, :type, String.upcase(to_string(type)))
        end)
      else
        []
      end
    end)
  end

  defp flatten_dns_records(_), do: []

  defp format_dns_value(%{value: value}) when is_binary(value), do: value
  defp format_dns_value(%{address: address}) when is_binary(address), do: address
  defp format_dns_value(%{exchange: exchange}) when is_binary(exchange), do: exchange
  defp format_dns_value(%{name: name}) when is_binary(name), do: name
  defp format_dns_value(%{data: data}) when is_binary(data), do: data
  defp format_dns_value(_), do: "N/A"
end
