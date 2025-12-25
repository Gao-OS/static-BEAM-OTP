defmodule StaticBeamExample.Application do
  @moduledoc """
  Application module for StaticBeamExample.

  This is a minimal OTP application that demonstrates
  the static BEAM VM is working correctly.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Add your workers and supervisors here
      # {StaticBeamExample.Worker, []}
    ]

    opts = [strategy: :one_for_one, name: StaticBeamExample.Supervisor]

    # Print system info on startup
    IO.puts("\nStaticBeamExample starting...")
    StaticBeamExample.print_info()

    Supervisor.start_link(children, opts)
  end
end
