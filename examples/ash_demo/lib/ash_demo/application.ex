defmodule AshDemo.Application do
  @moduledoc """
  OTP Application for the Ash Demo.

  When started with `TRANSPORT=ssh` or `TRANSPORT=distributed`, the Ash TUI
  explorer is embedded in the supervision tree and available without running
  `mix ash.tui`.

  ## Examples

      # Local (no daemon — use mix ash.tui instead)
      mix run --no-halt

      # SSH daemon — connect with: ssh ash@localhost -p 2222 (password: tui)
      TRANSPORT=ssh mix run --no-halt

      # Distribution listener — attach from another node
      TRANSPORT=distributed elixir --sname app --cookie demo -S mix run --no-halt

  """

  use Application

  @impl true
  def start(_type, _args) do
    children = tui_children()

    Supervisor.start_link(children, strategy: :one_for_one, name: AshDemo.Supervisor)
  end

  defp tui_children do
    case System.get_env("TRANSPORT") do
      "ssh" ->
        state = load_state()

        [
          {AshTui.App,
           transport: :ssh,
           port: ssh_port(),
           auto_host_key: true,
           auth_methods: ~c"password",
           user_passwords: [{~c"ash", ~c"tui"}],
           app_opts: [state: state]}
        ]

      "distributed" ->
        state = load_state()

        [
          {AshTui.App, transport: :distributed, app_opts: [state: state]}
        ]

      _ ->
        []
    end
  end

  defp load_state do
    :ash_demo
    |> AshTui.Introspection.load()
    |> AshTui.State.new()
  end

  defp ssh_port do
    case System.get_env("PORT") do
      nil -> 2222
      port -> String.to_integer(port)
    end
  end
end
