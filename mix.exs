defmodule Revenuecat.MixProject do
  use Mix.Project

  def project do
    [
      app: :revenuecat,
      description: "Light RevenueCat client",
      version: "0.2.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {RevenueCat.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:mox, "~> 1.1", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/dvcrn/revenuecat.ex"}
    ]
  end

  defp aliases do
    [
      lint: ["credo --strict", "dialyzer"]
    ]
  end
end
