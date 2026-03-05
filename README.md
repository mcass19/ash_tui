# AshTui

[![Hex.pm](https://img.shields.io/hexpm/v/ash_tui.svg)](https://hex.pm/packages/ash_tui)
[![Docs](https://img.shields.io/badge/hex-docs-blue)](https://hexdocs.pm/ash_tui)
[![CI](https://github.com/mcass19/ash_tui/actions/workflows/ci.yml/badge.svg)](https://github.com/mcass19/ash_tui/actions/workflows/ci.yml)
[![License](https://img.shields.io/hexpm/l/ash_tui.svg)](https://github.com/mcass19/ash_tui/blob/main/LICENSE)

Terminal-based interactive explorer for [Ash Framework](https://ash-hq.org) applications, built on [ExRatatui](https://github.com/mcass19/ex_ratatui).

Navigate your domains, resources, attributes, actions, and relationships — without leaving the terminal.

<!-- TODO: Add screenshot here -->
<!-- ![AshTui Explorer](assets/screenshot.png) -->

## Features

- Two-panel navigable interface with domain/resource tree
- Three detail tabs: Attributes, Actions, Relationships
- Attribute detail overlay — press Enter for full details including constraints
- Relationship navigation with breadcrumb trail and back stack
- Vim keybindings (`j`/`k`/`h`/`l`) and arrow key support
- Tab switching with `Tab` or `1`/`2`/`3`
- Help overlay
- No database connection needed — reads compile-time metadata only
- `mix ash.tui` task for instant launch

## UI Layout

```
┌─ Navigation ─────────┐ ┌─ Accounts.User ─────────────────────┐
│                       │ │                                      │
│  Accounts             │ │  [1:Attributes]  2:Actions  3:Rels   │
│    > User             │ │ ┌──────────────────────────────────┐ │
│      Token            │ │ │ Name        Type       Required? │ │
│  Blog                 │ │ │ ────        ────       ────────  │ │
│                       │ │ │ :id         :uuid      auto      │ │
│                       │ │ │ :email      :ci_string yes       │ │
│                       │ │ │ :name       :string    no        │ │
│                       │ │ │ :role       :atom      no        │ │
│                       │ │ └──────────────────────────────────┘ │
│ q:quit  ?:help        │ │ j/k:navigate  Enter:drill in  q:quit│
└───────────────────────┘ └──────────────────────────────────────┘
```

## Installation

Add `ash_tui` to your dependencies (`:dev` only recommended):

```elixir
def deps do
  [
    {:ash_tui, "~> 0.1.0", only: :dev}
  ]
end
```

## Usage

Launch the explorer from your Ash project:

```bash
mix ash.tui
```

The OTP app is auto-detected from your `mix.exs`. To specify it explicitly:

```bash
mix ash.tui --otp-app my_app
```

You can also launch programmatically:

```elixir
AshTui.explore(:my_app)
```

## How It Works

AshTui uses Ash's compile-time introspection API to load your domain model:

```
mix ash.tui
  → Mix.Task.run("app.start")
  → Ash.Info.domains(otp_app)
  → Ash.Domain.Info.resources(domain)
  → Ash.Resource.Info.attributes/actions/relationships(resource)
  → Pre-loaded into navigable state struct
  → ExRatatui.App renders it
```

No database connection is needed. The tool reads the *shape* of your app, not its data.

## Keybindings

### Navigation

| Key | Action |
|-----|--------|
| `j` / `Down` | Move selection down |
| `k` / `Up` | Move selection up |
| `h` / `Left` | Focus navigation panel |
| `l` / `Right` | Focus detail panel |
| `Enter` | Select item / drill into relationship / show attribute detail |
| `Esc` | Go back / close overlay |

### Tabs

| Key | Action |
|-----|--------|
| `Tab` | Cycle through tabs |
| `1` | Attributes tab |
| `2` | Actions tab |
| `3` | Relationships tab |

### Other

| Key | Action |
|-----|--------|
| `?` | Toggle help overlay |
| `q` | Quit |

## Example App

The `examples/ash_demo` directory contains a small Ash application with two domains (Accounts and Blog) for trying out the explorer:

```bash
cd examples/ash_demo
mix deps.get
mix ash.tui
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

AshTui is built on [ExRatatui](https://github.com/mcass19/ex_ratatui), a general-purpose terminal UI library for Elixir. If you're interested in improving the underlying rendering, widgets, or layout engine, contributions to ExRatatui are very welcome as well.

## License

MIT — see [LICENSE](LICENSE).
