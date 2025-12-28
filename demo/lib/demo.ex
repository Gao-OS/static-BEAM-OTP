defmodule Demo do
  @moduledoc """
  Demo application for testing static Erlang/OTP releases.
  Verifies crypto, SSL, and BEAM operations work correctly.
  """

  @doc """
  Verify crypto module works by generating a SHA256 hash.
  Returns {:ok, hash} on success, {:error, reason} on failure.
  """
  def verify_crypto do
    try do
      hash = :crypto.hash(:sha256, "test") |> Base.encode16(case: :lower)
      expected = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"

      if hash == expected do
        {:ok, hash}
      else
        {:error, "Hash mismatch: got #{hash}, expected #{expected}"}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Verify SSL/TLS works by making an HTTPS request.
  Returns {:ok, status} on success, {:error, reason} on failure.
  """
  def verify_ssl do
    try do
      :inets.start()
      :ssl.start()

      case :httpc.request(:get, {~c"https://httpbin.org/status/200", []}, [timeout: 10_000], []) do
        {:ok, {{_, status, _}, _, _}} when status in 200..299 ->
          {:ok, status}

        {:ok, {{_, status, _}, _, _}} ->
          {:error, "Unexpected status: #{status}"}

        {:error, reason} ->
          {:error, "Request failed: #{inspect(reason)}"}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Verify BEAM operations work by testing process spawning and message passing.
  Returns {:ok, :passed} on success, {:error, reason} on failure.
  """
  def verify_beam do
    try do
      parent = self()

      # Test process spawning and message passing
      pid = spawn(fn ->
        receive do
          {:ping, from} -> send(from, :pong)
        after
          5000 -> :timeout
        end
      end)

      send(pid, {:ping, parent})

      receive do
        :pong -> {:ok, :passed}
      after
        5000 -> {:error, "Message passing timeout"}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Run all verification checks and return overall health status.
  Returns :ok if all checks pass, {:error, failures} otherwise.
  """
  def health_check do
    results = [
      {:crypto, verify_crypto()},
      {:ssl, verify_ssl()},
      {:beam, verify_beam()}
    ]

    failures =
      results
      |> Enum.filter(fn {_, result} -> match?({:error, _}, result) end)
      |> Enum.map(fn {name, {:error, reason}} -> {name, reason} end)

    case failures do
      [] ->
        IO.puts("Health check passed!")
        Enum.each(results, fn {name, {:ok, _}} ->
          IO.puts("  #{name}: OK")
        end)
        :ok

      _ ->
        IO.puts("Health check failed!")
        Enum.each(failures, fn {name, reason} ->
          IO.puts("  #{name}: FAILED - #{reason}")
        end)
        {:error, failures}
    end
  end

  @doc """
  Run health check and exit with appropriate code.
  Used for CLI invocation via `bin/demo eval`.
  """
  def run_health_check do
    case health_check() do
      :ok -> System.halt(0)
      {:error, _} -> System.halt(1)
    end
  end
end
