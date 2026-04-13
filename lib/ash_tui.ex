defmodule AshTui do
  @moduledoc """
  Terminal-based interactive explorer for Ash Framework applications.

  `ash_tui` provides a navigable two-panel TUI for discovering domains,
  resources, attributes, actions, and relationships in any Ash project.

  ## Usage

  Add `ash_tui` to your dependencies:

      def deps do
        [
          {:ash_tui, "~> 0.3"}
        ]
      end

  Then run:

      mix ash.tui

  ## Transports

  The same explorer can be served locally, over SSH, or over Erlang
  distribution — powered by [ExRatatui](https://hexdocs.pm/ex_ratatui)
  transports. See `explore/2` for options.

  ### Local (default)

      mix ash.tui

  ### SSH

      mix ash.tui --ssh
      # then: ssh ash@localhost -p 2222   (password: tui)

  ### Erlang Distribution

      # Terminal 1 — start the listener
      elixir --sname app --cookie demo -S mix ash.tui --distributed

      # Terminal 2 — attach from another node
      iex --sname local --cookie demo -S mix
      iex> ExRatatui.Distributed.attach(:"app@hostname", AshTui.App)
  """

  @doc """
  Launches the Ash TUI explorer for the given OTP app.

  Loads all Ash domains and resources via compile-time introspection,
  then starts an interactive terminal interface.

  ## Options

    * `:transport` — `:local` (default), `:ssh`, or `:distributed`.

  ### Local options

  Any extra options are forwarded to `AshTui.App`
  (e.g. `test_mode: {80, 24}`, `name: nil`).

  ### SSH options

  When `transport: :ssh`, these options configure the SSH daemon:

    * `:port` — TCP port (default `2222`).
    * `:auto_host_key` — generate a host key automatically (default `true`).
    * `:auth_methods` — e.g. `~c"password"` (default).
    * `:user_passwords` — e.g. `[{~c"ash", ~c"tui"}]` (default).

  Any other keyword is forwarded to `:ssh.daemon/2`. See the
  [ExRatatui SSH guide](https://hexdocs.pm/ex_ratatui/ssh_transport.html)
  for the full option reference.

  ### Distributed options

  When `transport: :distributed`, the function starts a listener that
  remote nodes attach to via `ExRatatui.Distributed.attach/3`:

      ExRatatui.Distributed.attach(:"app@hostname", AshTui.App)

  See the
  [ExRatatui Distribution guide](https://hexdocs.pm/ex_ratatui/distributed_transport.html)
  for details.

  ## Examples

      # Local
      AshTui.explore(:my_app)

      # SSH with defaults (port 2222, ash:tui password)
      AshTui.explore(:my_app, transport: :ssh)

      # SSH with custom port and credentials
      AshTui.explore(:my_app,
        transport: :ssh,
        port: 4000,
        user_passwords: [{~c"admin", ~c"secret"}]
      )

      # Distributed listener
      AshTui.explore(:my_app, transport: :distributed)

  """
  @spec explore(atom(), keyword()) :: :ok
  def explore(otp_app, opts \\ []) do
    data = AshTui.Introspection.load(otp_app)

    if data == [] do
      IO.puts(:stderr, """

      warning: No Ash domains found for :#{otp_app}.

      Make sure your config includes:

          config :#{otp_app}, ash_domains: [MyApp.SomeDomain]

      Or check that the --otp-app flag matches your application.
      """)
    end

    state = AshTui.State.new(data)
    transport = Keyword.get(opts, :transport, :local)

    start_opts =
      if transport == :local do
        [{:state, state} | opts]
      else
        app_opts = [{:state, state} | Keyword.get(opts, :app_opts, [])]
        opts = Keyword.put(opts, :app_opts, app_opts)

        case transport do
          :ssh -> ssh_defaults(opts)
          :distributed -> opts
        end
      end

    {:ok, pid} = AshTui.App.start_link(start_opts)

    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
    end
  end

  @doc """
  Applies default SSH options to the given keyword list.

  Defaults (all overridable via `opts`):

    * `:port` — `2222`
    * `:auto_host_key` — `true`
    * `:auth_methods` — `~c"password"`
    * `:user_passwords` — `[{~c"ash", ~c"tui"}]`
  """
  @spec ssh_defaults(keyword()) :: keyword()
  def ssh_defaults(opts) do
    opts
    |> Keyword.put_new(:port, 2222)
    |> Keyword.put_new(:auto_host_key, true)
    |> Keyword.put_new(:auth_methods, ~c"password")
    |> Keyword.put_new(:user_passwords, [{~c"ash", ~c"tui"}])
  end
end
