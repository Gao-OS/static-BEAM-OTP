defmodule StaticBeamExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :static_beam_example,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :ssl],
      mod: {StaticBeamExample.Application, []}
    ]
  end

  defp deps do
    []
  end

  defp releases do
    [
      static_beam_example: [
        # Include the static ERTS from our Nix build
        # Set this path to your static Erlang build output
        include_erts: static_erts_path(),

        # Strip debug symbols for smaller release
        strip_beams: true,

        # Cookie for distributed Erlang
        cookie: "static_beam_example_cookie",

        # Release steps
        steps: [:assemble, :tar],

        # Override the default sys.config
        config_providers: [],

        # Customize the release
        rel_templates_path: "rel",

        # Additional options
        quiet: false
      ]
    ]
  end

  # Get the static ERTS path from environment or use default
  defp static_erts_path do
    cond do
      # Check for environment variable first
      System.get_env("STATIC_ERTS_PATH") ->
        System.get_env("STATIC_ERTS_PATH")

      # Check for Nix build output in parent directory
      File.exists?("../result/lib/erlang") ->
        Path.expand("../result/lib/erlang")

      # Check common Nix store paths (won't exist until built)
      true ->
        # This will be replaced when building with static ERTS
        # For development, use system ERTS
        System.get_env("ERTS_ROOT") || true
    end
  end
end
