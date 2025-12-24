defmodule Domaindive.Repo.Migrations.CreateDomainAnalyses do
  use Ecto.Migration

  def change do
    create table(:domain_analyses) do
      add :address, :string, null: false
      add :whois_data, :text
      add :dns_records, :text
      add :nameservers, :text
      add :ssl_info, :text
      add :http_headers, :text
      add :geolocation, :text

      timestamps()
    end

    create unique_index(:domain_analyses, [:address])
  end
end
