defmodule PipelineExampleSimple.Mixfile do
  use Mix.Project

  def project do [
    app: :pipeline_example_simple,
    version: "0.1.0",
    elixir: "~> 1.2",
    build_embedded: Mix.env == :prod,
    start_permanent: Mix.env == :prod,
    deps: deps,
  ] end

  def application do [
    applications: [:logger, :cowboy],
    mod: {MyApplication, []},
  ] end

  defp deps do [
    # Monadic effects.
    {:pipeline, path: "../../"},
    # Plug things.
    {:plug, "1.1.2"},
    # Cowboy server.
    {:cowboy, "~> 1.0.4"},
  ] end
end
