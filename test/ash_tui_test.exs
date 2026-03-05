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
      # We cannot use GenServer.stop because terminate/2 calls System.stop(0).
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
end
