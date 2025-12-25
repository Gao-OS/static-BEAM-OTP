defmodule StaticBeamExample do
  @moduledoc """
  Example Elixir application demonstrating static BEAM releases.

  This application serves as a minimal example of how to build and
  deploy Elixir applications using a statically-linked BEAM VM.
  """

  @doc """
  Hello world function to verify the application works.

      iex> StaticBeamExample.hello()
      :world

  """
  def hello do
    :world
  end

  @doc """
  Get system information about the running BEAM VM.
  """
  def system_info do
    %{
      otp_release: :erlang.system_info(:otp_release) |> List.to_string(),
      erts_version: :erlang.system_info(:version) |> List.to_string(),
      system_architecture: :erlang.system_info(:system_architecture) |> List.to_string(),
      schedulers: :erlang.system_info(:schedulers),
      schedulers_online: :erlang.system_info(:schedulers_online),
      wordsize: :erlang.system_info(:wordsize) * 8,
      elixir_version: System.version(),
      build_info: build_info()
    }
  end

  @doc """
  Print formatted system information.
  """
  def print_info do
    info = system_info()

    IO.puts("""

    ╔══════════════════════════════════════════════════════════════════╗
    ║              Static BEAM Example - System Info                   ║
    ╚══════════════════════════════════════════════════════════════════╝

    OTP Release:        #{info.otp_release}
    ERTS Version:       #{info.erts_version}
    Elixir Version:     #{info.elixir_version}
    Architecture:       #{info.system_architecture}
    Word Size:          #{info.wordsize} bits
    Schedulers:         #{info.schedulers} (#{info.schedulers_online} online)

    Build Info:
      Static:           #{info.build_info[:static] || "unknown"}
      libc:             #{info.build_info[:libc] || "unknown"}

    This application is running on a statically-linked BEAM VM!
    """)
  end

  # Try to determine build information
  defp build_info do
    # Check if running on musl
    libc =
      case System.cmd("ldd", ["--version"], stderr_to_stdout: true) do
        {output, _} ->
          cond do
            String.contains?(output, "musl") -> "musl"
            String.contains?(output, "GLIBC") -> "glibc"
            String.contains?(output, "GNU") -> "glibc"
            true -> "unknown"
          end

        _ ->
          "unknown"
      end
      |> String.trim()
      |> then(fn
        "" -> "static (no dynamic linker)"
        other -> other
      end)

    %{
      static: check_if_static(),
      libc: libc
    }
  end

  defp check_if_static do
    # Try to find the beam.smp binary
    erts_path = :code.root_dir() |> List.to_string()

    beam_path =
      Path.join([erts_path, "erts-*", "bin", "beam.smp"])
      |> Path.wildcard()
      |> List.first()

    if beam_path do
      case System.cmd("file", [beam_path], stderr_to_stdout: true) do
        {output, 0} ->
          if String.contains?(output, "statically linked"), do: "yes", else: "no"

        _ ->
          "unknown"
      end
    else
      "unknown"
    end
  end
end
