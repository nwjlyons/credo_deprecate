defmodule CredoDeprecate.MixProject do
  use Mix.Project

  def project do
    [
      app: :credo_deprecate,
      version: "0.1.10",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: "https://github.com/nwjlyons/credo_deprecate",
      homepage_url: "https://github.com/nwjlyons/credo_deprecate"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Credo checks to prevent new usage of deprecated modules, functions, macros, and structs while allowing existing usage."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/nwjlyons/credo_deprecate"}
    ]
  end

  defp docs do
    [
      main: "CredoDeprecate",
      source_url: "https://github.com/nwjlyons/credo_deprecate"
    ]
  end
end
