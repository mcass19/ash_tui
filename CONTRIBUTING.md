# Contributing to AshTui

Thanks for your interest in contributing!

AshTui is a pure Elixir project built on [ExRatatui](https://github.com/mcass19/ex_ratatui).

Feel free to also consider contributing on the upstream library if you're missing a feature, or something is not working. Contributions are welcome everywhere!

This guide will help you get set up.

## Setup

1. Clone the repo:

```sh
git clone https://github.com/mcass19/ash_tui.git
cd ash_tui
```

2. Install dependencies:

- **Elixir** 1.17+ and **Erlang/OTP** 26+

3. Fetch deps and compile:

```sh
mix deps.get
mix compile
```

## Running Tests

```sh
mix test
```

> **Note:** CI enforces **95% test coverage**. If you add new public functions
> or branches, make sure to add corresponding tests. Run `mix test --cover`
> locally to check before pushing.

## Branching and Commits

- Branch from `main`
- Keep commits focused and atomic
- Use descriptive commit message prefixes: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`

## Pull Requests

Before submitting a PR, make sure the following pass:

```sh
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix test
mix dialyzer
```

- Keep PRs focused — one feature or fix per PR
- Add tests for new functionality
- Add `@doc`, `@spec`, and `@moduledoc` for new public functions and modules
- Update documentation (moduledocs, CHANGELOG, README if applicable)
- For breaking changes, include migration notes in the CHANGELOG
- Follow existing code style and patterns
- Ensure CI passes before requesting review
