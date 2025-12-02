defmodule Domaindive.Repo do
  use Ecto.Repo,
    otp_app: :domaindive,
    adapter: Ecto.Adapters.SQLite3
end
