# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **SSH transport** — serve the explorer over SSH via `mix ash.tui --ssh` or `AshTui.explore(:app, transport: :ssh)`. Multiple clients can connect simultaneously, each with an isolated session. Defaults to port 2222 with password auth (`ash` / `tui`). Custom port, credentials, and all `:ssh.daemon/2` options are supported
- **Erlang distribution transport** — start a listener via `mix ash.tui --distributed` or `AshTui.explore(:app, transport: :distributed)`. Remote BEAM nodes attach with `ExRatatui.Distributed.attach(node, AshTui.App)` — useful for headless servers and Nerves devices
- `--ssh`, `--distributed`, and `--port` flags on `mix ash.tui`
- Transport banner messages printed to the console when starting SSH or distributed mode
- `examples/ash_demo` now includes an `AshDemo.Application` module demonstrating how to embed the SSH daemon or distribution listener in a supervision tree (set `TRANSPORT=ssh` or `TRANSPORT=distributed`)
- `credo` dependency and `mix credo --strict` CI step for code linting
- CI enforces 95% test coverage threshold
- Missing doctests and field documentation for introspection structs, `State`, `Theme`, and all view modules
- Added coverage requirement note to CONTRIBUTING.md
- CONTRIBUTING.md now documents branching/commit conventions, credo in PR checklist, and documentation expectations

### Changed

- Bump `ex_ratatui` dependency from `~> 0.5.0` to `~> 0.7`
- Extended Elixir support to 1.17 and added CI matrix entry

### Fixed

- `AshTui.explore/2` opts now default to `[]` — previously the second argument was required

### Docs

- README now documents SSH and Erlang distribution transports with usage examples
- README installation section updated to cover non-dev usage for production transports
- Added cross-references to ExRatatui's SSH and distribution transport guides
- Expanded moduledoc prose for `AshTui`, `AshTui.App`, introspection structs, `State`, `Theme`, and view modules

### Tests

- Bumped test coverage to 100% — added introspection, state, view, and app tests

## [0.2.0] - 2026-03-22

### Changed

- Bump `ex_ratatui` dependency from `~> 0.4.2` to `~> 0.5.0`
- Replace hand-rolled Paragraph tab bar with the proper `Tabs` widget
- Boolean fields in attribute detail overlay (Primary Key, Generated, Allow Nil) now render with checkbox-style indicators (`[✓]`/`[ ]`) instead of key-value text

### Added

- Search/filter for the navigation panel — press `/` to activate, type to filter resources, `Enter` to confirm, `Esc` to clear
- `Scrollbar` on the navigation list and all three detail tables when content overflows the viewport

## [0.1.1] - 2026-03-09

## Fixed

- Removed some unnecessary emojis
- Update links on docs

## [0.1.0] - 2026-03-06

### Added

- Two-panel terminal explorer for Ash Framework domains and resources
- `AshTui.Introspection` module for loading domain/resource metadata via Ash's compile-time introspection API
- `AshTui.State` module with pure navigation logic, tab switching, and nav stack
- Navigation panel with domain/resource list and focus-aware borders
- Attributes tab showing name, type, and required status
- Actions tab showing name, type, primary?, and arguments
- Relationships tab with navigable links to destination resources
- Relationship navigation with breadcrumb trail and Esc to go back
- Vim keybindings (`j`/`k`/`h`/`l`/Enter/Esc) and arrow key support
- Tab switching with `Tab` or `1`/`2`/`3` keys
- Help overlay (`?` to toggle)
- `mix ash.tui` task with `--otp-app` option
- Example Ash app (`examples/ash_demo`) with Accounts and Blog domains
- Test suite for introspection, state transitions, and navigation
- Attribute detail overlay — press `Enter` on any attribute to see full details (type, constraints, primary key, generated, etc.) in a centered modal
- `AshTui.Views.AttributeDetail` view module for rendering the overlay
- Footer keybinding hints now show `j/k/h/l` alongside arrow keys
- Removed Constraints column from the attributes table to avoid truncation — constraints are now shown in the attribute detail overlay instead

[Unreleased]: https://github.com/mcass19/ash_tui/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mcass19/ash_tui/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/mcass19/ash_tui/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/mcass19/ash_tui/releases/tag/v0.1.0
