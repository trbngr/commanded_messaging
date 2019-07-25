defmodule EsMessaging.MixProject do
  use Mix.Project

  def project do
    [
      app: :commanded_messaging,
      version: "0.1.0",
      elixir: "~> 1.6",
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib"] ++ Path.wildcard("test/**/support")
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      included_applications: [:commanded]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.0"},
      {:elixir_uuid, "~> 1.2", only: :test},
      {:exconstructor, "~> 1.1"},
      {:jason, "~> 1.1"},
      {:commanded, github: "commanded/commanded", only: :test}
    ]
  end

  defp aliases do
    [
      test: ["test --no-start"]
    ]
  end
end
