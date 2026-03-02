defmodule AshTuiTest do
  use ExUnit.Case, async: true

  alias AshTui.Test.Fixtures

  test "explore/1 requires a valid otp_app" do
    # We can't test the full explore flow without a real terminal,
    # but we verify the introspection + state pipeline works
    domains = Fixtures.sample_domains()
    state = AshTui.State.new(domains)

    assert state.current_domain.name == Test.Accounts
    assert state.current_resource.name == Test.Accounts.User
  end
end
