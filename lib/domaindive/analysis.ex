defmodule Domaindive.Analysis do
  @moduledoc """
  Context for domain analysis operations.
  """

  import Ecto.Query, warn: false
  alias Domaindive.Repo
  alias Domaindive.Analysis.DomainAnalysis
  alias Domaindive.Analysis.WhoisService
  alias Domaindive.Analysis.DnsService
  alias Domaindive.Analysis.SslService
  alias Domaindive.Analysis.HttpService
  alias Domaindive.Analysis.GeolocationService

  @cache_ttl_minutes 5

  @doc """
  Gets or creates a domain analysis for the given address.

  If a cached analysis exists and is older than #{@cache_ttl_minutes} minutes, it will be refreshed.
  Returns `{:ok, domain_analysis, :cached}` for cached data or `{:ok, domain_analysis, :fresh}` for new/refreshed data.
  """
  def get_or_create_analysis(address, force_refresh \\ false) do
    normalized_address = normalize_address(address)

    case Repo.get_by(DomainAnalysis, address: normalized_address) do
      nil ->
        case create_new_analysis(normalized_address) do
          {:ok, analysis} -> {:ok, analysis, :fresh}
          error -> error
        end

      existing_analysis ->
        if force_refresh || needs_refresh?(existing_analysis) do
          case refresh_analysis(existing_analysis) do
            {:ok, analysis} -> {:ok, analysis, :fresh}
            _error -> {:ok, existing_analysis, :cached}
          end
        else
          {:ok, existing_analysis, :cached}
        end
    end
  end

  @doc """
  Checks if an analysis needs to be refreshed based on its updated_at timestamp.
  """
  def needs_refresh?(%DomainAnalysis{updated_at: nil}), do: true

  def needs_refresh?(%DomainAnalysis{updated_at: updated_at}) do
    updated_at_utc = DateTime.from_naive!(updated_at, "Etc/UTC")
    age_minutes = DateTime.diff(DateTime.utc_now(), updated_at_utc, :minute)
    age_minutes >= @cache_ttl_minutes
  end

  @doc """
  Calculates seconds until the next refresh is needed.
  """
  def seconds_until_refresh(%DomainAnalysis{updated_at: nil}), do: 0

  def seconds_until_refresh(%DomainAnalysis{updated_at: updated_at}) do
    updated_at_utc = DateTime.from_naive!(updated_at, "Etc/UTC")
    refresh_time = DateTime.add(updated_at_utc, @cache_ttl_minutes * 60, :second)
    max(0, DateTime.diff(refresh_time, DateTime.utc_now(), :second))
  end

  defp refresh_analysis(existing_analysis) do
    perform_analysis(existing_analysis.address)
    |> case do
      {:ok, attrs} ->
        existing_analysis
        |> DomainAnalysis.changeset(attrs)
        |> Repo.update()

      error ->
        error
    end
  end

  defp create_new_analysis(normalized_address) do
    case perform_analysis(normalized_address) do
      {:ok, attrs} ->
        %DomainAnalysis{}
        |> DomainAnalysis.changeset(attrs)
        |> Repo.insert()

      error ->
        error
    end
  end

  defp perform_analysis(normalized_address) do
    whois_data =
      case WhoisService.fetch(normalized_address) do
        {:ok, data} -> data
        {:error, _} -> nil
      end

    dns_records =
      try do
        dns_data = DnsService.fetch_records(normalized_address)
        Jason.encode!(dns_data)
      rescue
        e ->
          IO.inspect(e, label: "DNS encoding error")
          Jason.encode!(%{})
      end

    nameservers =
      case DnsService.fetch_nameservers(normalized_address) do
        {:ok, data} -> Jason.encode!(data)
        {:error, _} -> Jason.encode!([])
      end

    {:ok, ssl_data} = SslService.fetch_certificate(normalized_address)
    ssl_info = Jason.encode!(ssl_data)

    http_response =
      case HttpService.fetch_headers(normalized_address) do
        {:ok, data} -> Jason.encode!(data)
        {:error, _} -> Jason.encode!(%{})
      end

    geolocation =
      case get_geolocation_for_domain(normalized_address) do
        {:ok, data} -> Jason.encode!(data)
        {:error, _} -> Jason.encode!(%{})
      end

    {:ok,
     %{
       address: normalized_address,
       whois_data: whois_data,
       dns_records: dns_records,
       nameservers: nameservers,
       ssl_info: ssl_info,
       http_response: http_response,
       geolocation: geolocation
     }}
  end

  defp get_geolocation_for_domain(domain) do
    try do
      case DnsService.fetch_records(domain) do
        # Match when we have at least one A record with a value
        %{a: [%{value: ip} | _]} ->
          GeolocationService.fetch_location(ip)

        # No A records found or empty list
        _ ->
          {:error, :no_ip}
      end
    rescue
      e ->
        # Log the actual error for debugging
        IO.inspect(e, label: "Geolocation lookup error")
        {:error, :lookup_failed}
    end
  end

  @doc """
  Gets a domain analysis by address.

  Returns `nil` if no analysis exists.

  ## Examples

      iex> get_analysis_by_address("example.com")
      %DomainAnalysis{}

      iex> get_analysis_by_address("nonexistent.com")
      nil

  """
  def get_analysis_by_address(address) do
    normalized_address = normalize_address(address)
    Repo.get_by(DomainAnalysis, address: normalized_address)
  end

  defp normalize_address(address) do
    address
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/^https?:\/\//, "")
    |> String.replace(~r/\/$/, "")
  end
end
