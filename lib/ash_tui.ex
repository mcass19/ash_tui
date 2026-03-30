defmodule AshTui do
  @moduledoc """
  Terminal-based interactive explorer for Ash Framework applications.

  `ash_tui` provides a navigable two-panel TUI for discovering domains,
  resources, attributes, actions, and relationships in any Ash project.

  ## Usage

  Add `ash_tui` to your dependencies (`:dev` only):

      def deps do
        [
          {:ash_tui, "~> 0.2", only: :dev}
        ]
      end

  Then run:

      mix ash.tui
  """

  @doc """
  Launches the Ash TUI explorer for the given OTP app.

  Loads all Ash domains and resources via compile-time introspection,
  then starts an interactive terminal interface.

  ## Options

  Any extra options are forwarded to `AshTui.App.start_link/1`
  (e.g. `test_mode: {80, 24}`, `name: nil`).
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

    {:ok, pid} = AshTui.App.start_link([{:state, state} | opts])

    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, :process, ^pid, _reason} -> :ok
    end
  end
end
