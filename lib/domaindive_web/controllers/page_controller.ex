defmodule DomaindiveWeb.PageController do
  use DomaindiveWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
