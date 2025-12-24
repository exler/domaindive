defmodule DomaindiveWeb.PageControllerTest do
  use DomaindiveWeb.ConnCase

  alias Domaindive.Analysis

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Dive Deep Into Any Domain"
  end

  test "GET /analysis with domain", %{conn: conn} do
    conn = get(conn, ~p"/analysis?domain=example.com")
    assert html_response(conn, 200) =~ "Domain Analysis Results"
    assert html_response(conn, 200) =~ "example.com"
  end

  test "GET /analysis creates domain analysis record", %{conn: conn} do
    domain = "test-domain.com"

    assert is_nil(Analysis.get_analysis_by_address(domain))

    conn = get(conn, ~p"/analysis?domain=#{domain}")
    assert html_response(conn, 200) =~ domain

    assert %Domaindive.Analysis.DomainAnalysis{address: ^domain} =
             Analysis.get_analysis_by_address(domain)
  end

  test "GET /analysis with existing domain returns same record", %{conn: conn} do
    domain = "existing-domain.com"

    {:ok, first_analysis} = Analysis.get_or_create_analysis(domain)

    conn = get(conn, ~p"/analysis?domain=#{domain}")
    assert html_response(conn, 200) =~ domain

    second_analysis = Analysis.get_analysis_by_address(domain)

    assert first_analysis.id == second_analysis.id
    assert first_analysis.inserted_at == second_analysis.inserted_at
  end

  test "GET /analysis normalizes domain address", %{conn: conn} do
    conn = get(conn, ~p"/analysis?domain=EXAMPLE.COM")
    assert html_response(conn, 200) =~ "example.com"

    assert %Domaindive.Analysis.DomainAnalysis{address: "example.com"} =
             Analysis.get_analysis_by_address("example.com")
  end

  test "GET /analysis strips protocol from domain", %{conn: conn} do
    conn = get(conn, ~p"/analysis?domain=https://example.org")
    assert html_response(conn, 200) =~ "example.org"

    assert %Domaindive.Analysis.DomainAnalysis{address: "example.org"} =
             Analysis.get_analysis_by_address("example.org")
  end

  test "GET /analysis rejects domain without TLD", %{conn: conn} do
    conn = get(conn, ~p"/analysis?domain=test")
    assert redirected_to(conn) == ~p"/"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "top-level domain"
  end

  test "GET /analysis rejects localhost", %{conn: conn} do
    conn = get(conn, ~p"/analysis?domain=localhost")
    assert redirected_to(conn) == ~p"/"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "top-level domain"
  end
end
