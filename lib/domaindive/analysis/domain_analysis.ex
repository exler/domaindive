defmodule Domaindive.Analysis.DomainAnalysis do
  @moduledoc """
  Schema for storing domain analysis data.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "domain_analyses" do
    field :address, :string
    field :whois_data, :string
    field :dns_records, :string
    field :nameservers, :string
    field :ssl_info, :string
    field :http_response, :string
    field :geolocation, :string

    timestamps()
  end

  @doc false
  def changeset(domain_analysis, attrs) do
    domain_analysis
    |> cast(attrs, [
      :address,
      :whois_data,
      :dns_records,
      :nameservers,
      :ssl_info,
      :http_response,
      :geolocation
    ])
    |> validate_required([:address])
    |> validate_format(:address, ~r/^[a-zA-Z0-9][a-zA-Z0-9-_.]+\.[a-zA-Z]{2,}$/,
      message: "must be a valid domain name with a top-level domain (e.g., example.com)"
    )
    |> unique_constraint(:address)
  end
end
