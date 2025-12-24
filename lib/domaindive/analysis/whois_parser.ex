defmodule Domaindive.Analysis.WhoisParser do
  @moduledoc """
  Parses WHOIS data to extract key information.
  """

  @doc """
  Parses WHOIS data and returns a map of extracted fields.
  """
  def parse(nil), do: %{}

  def parse(whois_data) do
    %{
      registrar: extract_field(whois_data, ["Registrar:", "Registrar Name:"]),
      created_date: extract_field(whois_data, ["Creation Date:", "Created Date:"]),
      expiry_date:
        extract_field(whois_data, ["Registry Expiry Date:", "Expiration Date:", "Expiry Date:"]),
      updated_date: extract_field(whois_data, ["Updated Date:", "Last Updated:"]),
      status: extract_status(whois_data),
      name_servers: extract_name_servers(whois_data)
    }
  end

  defp extract_field(data, field_names) do
    Enum.find_value(field_names, fn field_name ->
      case Regex.run(~r/#{Regex.escape(field_name)}\s*(.+)/i, data) do
        [_, value] -> String.trim(value)
        _ -> nil
      end
    end)
  end

  defp extract_status(data) do
    case Regex.scan(~r/Domain Status:\s*(.+)/i, data) do
      [] ->
        nil

      matches ->
        matches
        |> Enum.map(fn [_, status] -> String.trim(status) end)
        |> Enum.join(", ")
    end
  end

  defp extract_name_servers(data) do
    case Regex.scan(~r/Name Server:\s*(.+)/i, data) do
      [] ->
        []

      matches ->
        matches
        |> Enum.map(fn [_, ns] -> String.trim(String.downcase(ns)) end)
        |> Enum.uniq()
    end
  end
end
