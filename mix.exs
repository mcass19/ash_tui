defmodule AshTui.MixProject do
  use Mix.Project

  @description "Terminal-based interactive explorer for Ash Framework applications"
  @source_url "https://github.com/mcass19/ash_tui"
  @changelog_url @source_url <> "/blob/main/CHANGELOG.md"
  @version "0.2.0"

  def project do
    [
      app: :ash_tui,
      description: @description,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      test_coverage: [
        threshold: 95,
        ignore_modules: [
          Mix.Tasks.Ash.Tui,
          AshTui.Test.TestDomain,
          Inspect.AshTui.Test.Author,
          Inspect.AshTui.Test.Post
        ]
      ],
      package: package(),
      name: "AshTui",
      homepage_url: @source_url,
      source_url: @source_url,
      docs: docs(),
      dialyzer: [
        plt_local_path: "plts",
        plt_core_path: "plts/core",
        plt_add_apps: [:mix]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ash, "~> 3.19"},
      {:ex_ratatui, "~> 0.7"},

      # Dev
      {:ex_doc, "~> 0.35", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @changelog_url
      },
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      keywords: ["ash", "tui", "terminal", "explorer", "introspection", "ratatui"]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        "README.md": [title: "Overview"],
        "CONTRIBUTING.md": [title: "Contributing"],
        "CHANGELOG.md": [title: "Changelog"]
      ],
      groups_for_modules: [
        Core: [
          AshTui,
          AshTui.App,
          AshTui.Format,
          AshTui.Theme
        ],
        Introspection: [
          AshTui.Introspection,
          AshTui.Introspection.DomainInfo,
          AshTui.Introspection.ResourceInfo,
          AshTui.Introspection.AttributeInfo,
          AshTui.Introspection.ActionInfo,
          AshTui.Introspection.ArgumentInfo,
          AshTui.Introspection.RelationshipInfo
        ],
        State: [
          AshTui.State
        ],
        Views: [
          AshTui.Views.NavPanel,
          AshTui.Views.AttributesTab,
          AshTui.Views.AttributeDetail,
          AshTui.Views.ActionsTab,
          AshTui.Views.RelationshipsTab
        ],
        "Mix Tasks": [
          Mix.Tasks.Ash.Tui
        ]
      ]
    ]
  end
end
