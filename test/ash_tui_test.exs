defmodule AshTuiTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Test.Fixtures

  describe "App lifecycle with test_mode" do
    test "boots in headless mode" do
      state = State.new(Fixtures.sample_domains())

      {:ok, pid} =
        AshTui.App.start_link(
          state: state,
          name: nil,
          test_mode: {80, 24}
        )

      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "State.new/1 pipeline" do
    test "creates navigable state from introspection data" do
      state = State.new(Fixtures.sample_domains())

      assert state.current_domain.name == Test.Accounts
      assert state.current_resource.name == Test.Accounts.User
      assert state.current_tab == :attributes
      assert state.focus == :nav
      assert state.detail_overlay == nil
    end
  end

  describe "explore/2" do
    test "with no domains prints warning and starts app" do
      app_name = :"ash_tui_test_warn_#{:erlang.unique_integer([:positive])}"

      warning =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          task =
            Task.async(fn ->
              AshTui.explore(:ash_tui_not_configured, test_mode: {80, 24}, name: app_name)
            end)

          pid = await_registered(app_name)
          GenServer.stop(pid)
          Task.await(task, 1000)
        end)

      assert warning =~ "No Ash domains found"
    end

    test "with domains starts app without warning" do
      Application.put_env(:ash_tui_test_app, :ash_domains, [AshTui.Test.TestDomain])
      app_name = :"ash_tui_test_domains_#{:erlang.unique_integer([:positive])}"

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          task =
            Task.async(fn ->
              AshTui.explore(:ash_tui_test_app, test_mode: {80, 24}, name: app_name)
            end)

          pid = await_registered(app_name)
          GenServer.stop(pid)
          Task.await(task, 1000)
        end)

      assert output == ""
    after
      Application.delete_env(:ash_tui_test_app, :ash_domains)
    end

    test "explore/1 boots locally with default options via the configured starter" do
      test = self()

      Application.put_env(:ash_tui, :app_starter, fn _start_opts ->
        {:ok, pid} = Agent.start_link(fn -> :ok end)
        send(test, {:started, pid})
        {:ok, pid}
      end)

      on_exit(fn -> Application.delete_env(:ash_tui, :app_starter) end)

      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        task = Task.async(fn -> AshTui.explore(:ash_tui_no_domains) end)
        assert_receive {:started, pid}
        Agent.stop(pid)
        assert Task.await(task) == :ok
      end)
    end

    test "ssh transport applies default options" do
      defaults = AshTui.ssh_defaults(transport: :ssh)

      assert defaults[:port] == 2222
      assert defaults[:auto_host_key] == true
      assert defaults[:auth_methods] == ~c"password"
      assert defaults[:user_passwords] == [{~c"ash", ~c"tui"}]
    end

    test "ssh transport preserves custom options" do
      opts = [transport: :ssh, port: 4000, user_passwords: [{~c"admin", ~c"secret"}]]
      defaults = AshTui.ssh_defaults(opts)

      assert defaults[:port] == 4000
      assert defaults[:user_passwords] == [{~c"admin", ~c"secret"}]
      assert defaults[:auto_host_key] == true
    end
  end

  describe "build_start_opts/2" do
    test "local transport prepends the state" do
      state = State.new(Fixtures.sample_domains())

      assert AshTui.build_start_opts(state, [])[:state] == state
    end

    test "ssh transport nests state under app_opts and merges defaults" do
      state = State.new(Fixtures.sample_domains())
      opts = AshTui.build_start_opts(state, transport: :ssh)

      assert opts[:transport] == :ssh
      assert opts[:port] == 2222
      assert opts[:app_opts][:state] == state
    end

    test "distributed transport nests state under app_opts" do
      state = State.new(Fixtures.sample_domains())
      opts = AshTui.build_start_opts(state, transport: :distributed)

      assert opts[:transport] == :distributed
      assert opts[:app_opts][:state] == state
    end
  end

  defp await_registered(name, attempts \\ 200) do
    case Process.whereis(name) do
      nil when attempts > 0 ->
        Process.sleep(5)
        await_registered(name, attempts - 1)

      pid when is_pid(pid) ->
        pid

      nil ->
        raise "Process #{inspect(name)} was not registered in time"
    end
  end
end
