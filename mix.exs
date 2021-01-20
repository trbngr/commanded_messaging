defmodule EsMessaging.MixProject do
  use Mix.Project

  @version "0.2.8"

  def project do
    [
      app: :commanded_messaging,
      version: @version,
      elixir: "~> 1.9",
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Common macros for messaging in a Commanded application*",
      source_url: "https://github.com/trbngr/commanded_messaging",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/trbngr/commanded_messaging"}
      ],
      docs: [
        main: "readme",
        source_ref: "v#{@version}",
        extras: ["README.md"]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib"] ++ Path.wildcard("test/**/support")
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    if Mix.env() == :test do
      [included_applications: [:commanded]]
    else
      []
    end
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.3"},
      {:elixir_uuid, "~> 1.2", only: :test},
      {:exconstructor, "~> 1.1"},
      {:jason, "~> 1.1"},
      {:commanded, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["test --no-start"]
    ]
  end
end
