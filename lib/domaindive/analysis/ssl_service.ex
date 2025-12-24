defmodule Domaindive.Analysis.SslService do
  @moduledoc """
  Service for retrieving SSL certificate information.
  """

  @doc """
  Fetches SSL certificate information for a domain.
  """
  def fetch_certificate(domain) do
    # First resolve the domain to an IP
    case resolve_domain(domain) do
      {:ok, ip} ->
        connect_and_get_cert(ip, domain)

      {:error, _} ->
        {:ok, %{available: false}}
    end
  end

  defp resolve_domain(domain) do
    charlist_domain = String.to_charlist(domain)

    case :inet.gethostbyname(charlist_domain) do
      {:ok, {:hostent, _name, _aliases, :inet, _length, [ip | _]}} ->
        {:ok, ip}

      _ ->
        {:error, :resolution_failed}
    end
  end

  defp connect_and_get_cert(ip, domain) do
    charlist_domain = String.to_charlist(domain)

    ssl_opts = [
      verify: :verify_none,
      server_name_indication: charlist_domain,
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]

    case :ssl.connect(ip, 443, ssl_opts, 10_000) do
      {:ok, socket} ->
        cert_info = extract_certificate_info(socket)
        :ssl.close(socket)
        {:ok, cert_info}

      {:error, _reason} ->
        {:ok, %{available: false}}
    end
  end

  defp extract_certificate_info(socket) do
    case :ssl.peercert(socket) do
      {:ok, cert} ->
        parse_certificate(cert)

      {:error, _reason} ->
        %{available: false}
    end
  end

  defp parse_certificate(cert) do
    decoded = :public_key.pkix_decode_cert(cert, :otp)

    case decoded do
      {:OTPCertificate, tbs_cert, _sig_alg, _signature} ->
        extract_cert_fields(tbs_cert)

      _ ->
        %{available: false}
    end
  rescue
    _ ->
      %{available: false}
  end

  defp extract_cert_fields(tbs_cert) do
    {:OTPTBSCertificate, _version, _serial, _sig_alg, issuer, validity, subject, _public_key_info,
     _issuer_id, _subject_id, extensions} = tbs_cert

    %{
      available: true,
      subject: extract_subject(subject),
      issuer: extract_issuer(issuer),
      valid_from: extract_validity_date(validity, :notBefore),
      valid_to: extract_validity_date(validity, :notAfter),
      san: extract_san(extensions)
    }
  rescue
    _ ->
      %{available: false}
  end

  defp extract_subject({:rdnSequence, rdn_sequence}) do
    extract_name_from_rdn(rdn_sequence, "CN")
  end

  defp extract_issuer({:rdnSequence, rdn_sequence}) do
    extract_name_from_rdn(rdn_sequence, "CN")
  end

  defp extract_name_from_rdn(rdn_sequence, oid_type) do
    oid =
      case oid_type do
        "CN" -> {2, 5, 4, 3}
        "O" -> {2, 5, 4, 10}
        _ -> nil
      end

    result =
      Enum.find_value(rdn_sequence, fn rdn_set ->
        Enum.find_value(rdn_set, fn
          {:AttributeTypeAndValue, ^oid, value} ->
            case value do
              {:utf8String, str} -> List.to_string(str)
              {:printableString, str} -> List.to_string(str)
              _ -> nil
            end

          _ ->
            nil
        end)
      end)

    result || "Unknown"
  end

  defp extract_validity_date({:Validity, not_before, not_after}, type) do
    date =
      case type do
        :notBefore -> not_before
        :notAfter -> not_after
      end

    case date do
      {:utcTime, time} ->
        parse_utc_time(time)

      {:generalTime, time} ->
        parse_general_time(time)

      _ ->
        nil
    end
  end

  defp parse_utc_time(time) do
    time_str = List.to_string(time)

    case time_str do
      <<yy::binary-2, mm::binary-2, dd::binary-2, hh::binary-2, min::binary-2, ss::binary-2, "Z">> ->
        year = String.to_integer(yy) + 2000
        "#{year}-#{mm}-#{dd} #{hh}:#{min}:#{ss} UTC"

      _ ->
        nil
    end
  end

  defp parse_general_time(time) do
    time_str = List.to_string(time)

    case time_str do
      <<yyyy::binary-4, mm::binary-2, dd::binary-2, hh::binary-2, min::binary-2, ss::binary-2,
        "Z">> ->
        "#{yyyy}-#{mm}-#{dd} #{hh}:#{min}:#{ss} UTC"

      _ ->
        nil
    end
  end

  defp extract_san(extensions) when is_list(extensions) do
    san_extension =
      Enum.find(extensions, fn ext ->
        case ext do
          {:Extension, {2, 5, 29, 17}, _, _} -> true
          _ -> false
        end
      end)

    case san_extension do
      {:Extension, {2, 5, 29, 17}, _critical, value} ->
        parse_san_value(value)

      _ ->
        []
    end
  end

  defp extract_san(:asn1_NOVALUE), do: []
  defp extract_san(_), do: []

  defp parse_san_value(value) when is_list(value) do
    Enum.map(value, fn
      {:dNSName, dns_name} when is_list(dns_name) -> List.to_string(dns_name)
      {:dNSName, dns_name} when is_binary(dns_name) -> dns_name
      _ -> nil
    end)
    |> Enum.filter(&(&1 != nil))
  end

  defp parse_san_value(_), do: []
end
