defmodule Domaindive.Analysis.DnsService do
  @moduledoc """
  Service for performing DNS lookups and retrieving DNS records.
  """

  @doc """
  Fetches DNS records for a given domain.

  Returns a map with different record types.

  ## Examples

      iex> fetch_records("example.com")
      %{
        a: [%{value: "93.184.216.34", ttl: 3600}],
        aaaa: [],
        mx: [],
        txt: [],
        cname: [],
        ns: [%{value: "ns1.example.com", ttl: 3600}]
      }
  """
  def fetch_records(domain) do
    %{
      a: lookup(domain, :a) |> unwrap_result(),
      aaaa: lookup(domain, :aaaa) |> unwrap_result(),
      mx: lookup(domain, :mx) |> unwrap_result(),
      txt: lookup(domain, :txt) |> unwrap_result(),
      cname: lookup(domain, :cname) |> unwrap_result()
    }
  end

  # Unwraps the {:ok, data} or {:error, _} tuple into plain data
  # Returns the list of records on success, or empty list on error
  # Required for Jason.encode to work properly
  defp unwrap_result({:ok, records}), do: records
  defp unwrap_result({:error, _reason}), do: []

  @doc """
  Fetches authoritative name servers for a domain.

  ## Examples

      iex> fetch_nameservers("example.com")
      {:ok, [
        %{hostname: "ns1.example.com", ip_address: "192.0.2.1"},
        %{hostname: "ns2.example.com", ip_address: "192.0.2.2"}
      ]}
  """
  def fetch_nameservers(domain) do
    case lookup(domain, :ns) do
      {:ok, nameservers} ->
        nameservers_with_ips =
          Enum.map(nameservers, fn ns_record ->
            hostname = ns_record.value

            ip_address =
              case lookup(hostname, :a) do
                {:ok, [ip | _]} -> ip.value
                _ -> nil
              end

            %{hostname: hostname, ip_address: ip_address}
          end)

        {:ok, nameservers_with_ips}

      error ->
        error
    end
  end

  # Performs DNS lookup for a specific domain and record type
  defp lookup(domain, type) do
    charlist_domain = String.to_charlist(domain)

    case :inet_res.resolve(charlist_domain, :in, type) do
      {:ok, dns_rec} ->
        records = extract_records(dns_rec, type)
        {:ok, records}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Extracts and filters records from the DNS response structure
  # The dns_rec tuple structure is:
  # {:dns_rec, header, queries, answers, authority, additional}
  # We need to extract from the answers list (3rd element, index 2)
  defp extract_records(dns_rec, type) do
    # Pattern match to extract the answers list from the dns_rec tuple
    {:dns_rec, _header, _queries, answers, _authority, _additional} = dns_rec

    Enum.reduce(answers, [], fn answer, acc ->
      # Match the dns_rr tuple structure from the answers list
      # Format: {:dns_rr, domain_charlist, record_type, class, cache_flag, ttl, data, undefined, empty_list, false}
      case answer do
        {:dns_rr, _domain, ^type, :in, _cache_flag, ttl, data, _, _, _} ->
          # Successfully matched the record type we're looking for
          [format_record(type, data, ttl) | acc]

        _ ->
          # Skip records that don't match our type
          acc
      end
    end)
    |> Enum.reverse()
  end

  # Format A record (IPv4 address)
  # Data format: {octet1, octet2, octet3, octet4}
  # Example: {51, 68, 147, 254} -> "51.68.147.254"
  defp format_record(:a, {a, b, c, d}, ttl) do
    %{value: "#{a}.#{b}.#{c}.#{d}", ttl: ttl}
  end

  # Format AAAA record (IPv6 address)
  # Data format: {hex1, hex2, hex3, hex4, hex5, hex6, hex7, hex8}
  # Example: {8193, 3512, 0, 0, 0, 0, 0, 1} -> "2001:db8::1"
  defp format_record(:aaaa, {a, b, c, d, e, f, g, h}, ttl) do
    value =
      [a, b, c, d, e, f, g, h]
      |> Enum.map(&Integer.to_string(&1, 16))
      |> Enum.join(":")
      |> String.downcase()

    %{value: value, ttl: ttl}
  end

  # Format MX record (Mail Exchange)
  # Data format: {priority, hostname_charlist}
  # Example: {10, ~c"mail.example.com"} -> %{value: "mail.example.com", priority: 10, ttl: 3600}
  defp format_record(:mx, {priority, hostname}, ttl) do
    %{value: to_string(hostname), priority: priority, ttl: ttl}
  end

  # Format TXT record (Text record)
  # Data format: charlist or list of charlists
  # Example: [~c"v=spf1 include:_spf.google.com ~all"] -> %{value: "v=spf1 include:_spf.google.com ~all", ttl: 3600}
  defp format_record(:txt, strings, ttl) when is_list(strings) do
    value = Enum.join(strings)
    %{value: value, ttl: ttl}
  end

  # Format CNAME record (Canonical Name)
  # Data format: hostname_charlist
  # Example: ~c"example.cdn.com" -> %{value: "example.cdn.com", ttl: 3600}
  defp format_record(:cname, hostname, ttl) do
    %{value: to_string(hostname), ttl: ttl}
  end

  # Format NS record (Name Server)
  # Data format: hostname_charlist
  # Example: ~c"ns1.example.com" -> %{value: "ns1.example.com", ttl: 3600}
  defp format_record(:ns, hostname, ttl) do
    %{value: to_string(hostname), ttl: ttl}
  end

  # Fallback formatter for any unhandled record types
  # Returns the raw data as an inspected string
  defp format_record(_, data, ttl) do
    %{value: inspect(data), ttl: ttl}
  end
end
