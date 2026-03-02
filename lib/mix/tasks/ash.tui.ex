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
    {opts, _rest} = OptionParser.parse!(args, strict: [otp_app: :string])

    otp_app =
      case Keyword.get(opts, :otp_app) do
        nil -> Mix.Project.config()[:app]
        app -> String.to_existing_atom(app)
      end

    Mix.Task.run("app.start")

    AshTui.explore(otp_app)
  end
end
