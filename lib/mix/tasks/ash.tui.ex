defmodule Mix.Tasks.Ash.Tui do
  @shortdoc "Launches the interactive Ash TUI explorer"

  @moduledoc """
  Starts an interactive terminal explorer for your Ash domains and resources.

      $ mix ash.tui

  The explorer loads all Ash domains registered in your application and
  displays them in a navigable two-panel interface. No database connection
  is required — it reads compile-time metadata only.

  ## Options

    * `--otp-app` - The OTP app to introspect. Defaults to the app
      defined in your `mix.exs`.
    * `--ssh` - Serve the explorer over SSH instead of the local terminal.
      Multiple clients can connect simultaneously, each with an isolated
      session. Defaults to port 2222 with password auth (`ash` / `tui`).
    * `--distributed` - Start a distribution listener. Remote BEAM nodes
      can attach via `ExRatatui.Distributed.attach/3`.
    * `--port PORT` - TCP port for SSH mode (default `2222`).

  ## Transports

  ### Local (default)

      $ mix ash.tui

  ### SSH

      $ mix ash.tui --ssh
      $ mix ash.tui --ssh --port 4000

      # then connect from another terminal:
      $ ssh ash@localhost -p 2222    # password: tui

  ### Erlang Distribution

      # Terminal 1 — start the listener
      $ elixir --sname app --cookie demo -S mix ash.tui --distributed

      # Terminal 2 — attach from another node
      $ iex --sname local --cookie demo -S mix
      iex> ExRatatui.Distributed.attach(:"app@hostname", AshTui.App)

  ## Keybindings

    * `j`/`k` or arrows — navigate up/down
    * `h`/`l` or arrows — switch focus between panels
    * `Enter` — select item or drill into relationship
    * `Esc` — go back
    * `Tab` or `1`/`2`/`3` — switch detail tabs
    * `?` — help overlay
    * `q` — quit
  """

  use Mix.Task

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    AshTui.CLI.main(args, &AshTui.explore/2)
  end
end
