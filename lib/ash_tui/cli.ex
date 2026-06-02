defmodule AshTui.CLI do
  @moduledoc false
  # Command-line logic behind `mix ash.tui`. Kept separate from the Mix
  # task so it can be tested without booting a terminal: the launcher is
  # injected (defaulting to `AshTui.explore/2`), and the banner is printed
  # through `Mix.shell/0`.

  @strict [otp_app: :string, ssh: :boolean, distributed: :boolean, port: :integer]

  @spec main([String.t()], (atom(), keyword() -> any())) :: any()
  def main(args, launcher) do
    {opts, _rest} = OptionParser.parse!(args, strict: @strict)

    otp_app =
      case Keyword.get(opts, :otp_app) do
        nil -> Mix.Project.config()[:app]
        app -> String.to_existing_atom(app)
      end

    explore_opts = explore_opts(opts)

    if explore_opts[:transport] do
      Mix.shell().info(transport_banner(explore_opts))
    end

    launcher.(otp_app, explore_opts)
  end

  defp explore_opts(opts) do
    cond do
      opts[:ssh] ->
        ssh_opts = [transport: :ssh]
        if port = opts[:port], do: Keyword.put(ssh_opts, :port, port), else: ssh_opts

      opts[:distributed] ->
        [transport: :distributed]

      true ->
        []
    end
  end

  defp transport_banner(opts) do
    case opts[:transport] do
      :ssh ->
        port = Keyword.get(opts, :port, 2222)

        """

        Ash TUI explorer running over SSH on port #{port}.
        Connect with: ssh ash@localhost -p #{port}  (password: tui)
        Press Ctrl+C to stop the daemon.
        """

      :distributed ->
        """

        Ash TUI explorer listening for distribution connections.
        Attach from another node: ExRatatui.Distributed.attach(:"#{Node.self()}", AshTui.App)
        Press Ctrl+C to stop the listener.
        """
    end
  end
end
