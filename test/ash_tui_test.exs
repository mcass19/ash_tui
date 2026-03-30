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

      # Unlink before killing to avoid taking down the test process.
      Process.unlink(pid)
      Process.exit(pid, :kill)
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

    test "explore/1 default opts clause is callable" do
      Process.flag(:trap_exit, true)

      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        assert_raise MatchError, fn ->
          AshTui.explore(:ash_tui_not_configured)
        end
      end)
    after
      Process.flag(:trap_exit, false)

      receive do
        {:EXIT, _, _} -> :ok
      after
        0 -> :ok
      end
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
