# Ash Demo — AshTui Example App

A small Ash application for demonstrating [AshTui](https://github.com/mcass19/ash_tui). Two domains with cross-domain relationships, using ETS (no database required).

## Domains

- **Accounts** — User, Token
- **Blog** — Post, Comment, Tag

## Setup

```bash
cd examples/ash_demo
mix deps.get
```

## Run

### Local

```bash
mix ash.tui
```

### SSH

```bash
mix ash.tui --ssh

# then connect from another terminal:
ssh ash@localhost -p 2222   # password: tui
```

### Erlang Distribution

```bash
# Terminal 1 — start the listener
elixir --sname app --cookie demo -S mix ash.tui --distributed

# Terminal 2 — attach from another node
iex --sname local --cookie demo -S mix
iex> ExRatatui.Distributed.attach(:"app@hostname", AshTui.App)
```

## Controls

| Key | Action |
|-----|--------|
| `j` / `Down` | Move selection down |
| `k` / `Up` | Move selection up |
| `h` / `Left` | Focus navigation panel |
| `l` / `Right` | Focus detail panel |
| `Enter` | Select / drill into relationship |
| `Esc` | Go back |
| `Tab` | Cycle tabs |
| `1`/`2`/`3` | Jump to tab |
| `?` | Help |
| `q` | Quit |
