defmodule Demo.MixProject do
  use Mix.Project

  def project do
    [
      app: :demo,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :ssl, :inets]
    ]
  end

  defp deps do
    []
  end

  defp releases do
    [
      demo: [
        include_erts: System.get_env("ERTS_PATH", "/opt/erlang/lib/erlang"),
        steps: [:assemble]
      ]
    ]
  end
end
