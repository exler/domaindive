defmodule Domaindive.Analysis.WhoisService do
  @moduledoc """
  Service for fetching WHOIS data from InterNIC.
  """

  @whois_server "whois.internic.net"
  @whois_port 43
  @timeout 10_000

  @doc """
  Fetches WHOIS data for a given domain from InterNIC.

  Returns `{:ok, whois_data}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> fetch("example.com")
      {:ok, "Domain Name: EXAMPLE.COM\\nRegistrar: ..."}

      iex> fetch("invalid")
      {:error, :timeout}

  """
  def fetch(domain) do
    with {:ok, socket} <-
           :gen_tcp.connect(~c"#{@whois_server}", @whois_port, [:binary, active: false], @timeout),
         :ok <- :gen_tcp.send(socket, "#{domain}\r\n"),
         {:ok, data} <- receive_data(socket, <<>>) do
      :gen_tcp.close(socket)
      {:ok, data}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp receive_data(socket, acc) do
    case :gen_tcp.recv(socket, 0, @timeout) do
      {:ok, data} ->
        receive_data(socket, acc <> data)

      {:error, :closed} ->
        {:ok, acc}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
