defmodule Domaindive.AnalysisTest do
  use Domaindive.DataCase

  alias Domaindive.Analysis

  describe "get_or_create_analysis/1" do
    test "creates a new domain analysis" do
      domain = "example.com"

      assert {:ok, analysis} = Analysis.get_or_create_analysis(domain)
      assert analysis.address == domain
      assert analysis.id
    end

    test "returns existing domain analysis" do
      domain = "existing.com"

      {:ok, first} = Analysis.get_or_create_analysis(domain)
      {:ok, second} = Analysis.get_or_create_analysis(domain)

      assert first.id == second.id
      assert first.address == second.address
    end

    test "normalizes domain address to lowercase" do
      {:ok, analysis} = Analysis.get_or_create_analysis("EXAMPLE.COM")
      assert analysis.address == "example.com"
    end

    test "strips http protocol from address" do
      {:ok, analysis} = Analysis.get_or_create_analysis("http://example.com")
      assert analysis.address == "example.com"
    end

    test "strips https protocol from address" do
      {:ok, analysis} = Analysis.get_or_create_analysis("https://example.com")
      assert analysis.address == "example.com"
    end

    test "strips trailing slash from address" do
      {:ok, analysis} = Analysis.get_or_create_analysis("example.com/")
      assert analysis.address == "example.com"
    end

    test "handles complex normalization" do
      {:ok, analysis} = Analysis.get_or_create_analysis("HTTPS://EXAMPLE.COM/")
      assert analysis.address == "example.com"
    end

    test "rejects domain without TLD" do
      assert {:error, changeset} = Analysis.get_or_create_analysis("test")
      errors = errors_on(changeset).address
      assert Enum.any?(errors, &String.contains?(&1, "top-level domain"))
    end

    test "rejects localhost" do
      assert {:error, changeset} = Analysis.get_or_create_analysis("localhost")
      errors = errors_on(changeset).address
      assert Enum.any?(errors, &String.contains?(&1, "top-level domain"))
    end

    test "rejects single word domains" do
      assert {:error, changeset} = Analysis.get_or_create_analysis("justword")
      errors = errors_on(changeset).address
      assert Enum.any?(errors, &String.contains?(&1, "top-level domain"))
    end

    test "accepts valid domain with subdomain" do
      assert {:ok, analysis} = Analysis.get_or_create_analysis("sub.example.com")
      assert analysis.address == "sub.example.com"
    end
  end

  describe "get_analysis_by_address/1" do
    test "returns nil when analysis doesn't exist" do
      assert is_nil(Analysis.get_analysis_by_address("nonexistent.com"))
    end

    test "returns analysis when it exists" do
      domain = "findme.com"
      {:ok, created} = Analysis.get_or_create_analysis(domain)

      found = Analysis.get_analysis_by_address(domain)

      assert found.id == created.id
      assert found.address == domain
    end

    test "normalizes address when searching" do
      {:ok, _created} = Analysis.get_or_create_analysis("example.com")

      found = Analysis.get_analysis_by_address("HTTPS://EXAMPLE.COM/")

      assert found.address == "example.com"
    end
  end
end
