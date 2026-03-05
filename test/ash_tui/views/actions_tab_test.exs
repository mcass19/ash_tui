defmodule AshTui.Views.ActionsTabTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Views.ActionsTab
  alias AshTui.Test.Fixtures
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Native

  setup do
    terminal = ExRatatui.init_test_terminal(70, 15)
    on_exit(fn -> Native.restore_terminal(terminal) end)
    state = State.new(Fixtures.sample_domains()) |> Map.put(:current_tab, :actions)
    rect = %Rect{x: 0, y: 0, width: 70, height: 15}
    %{terminal: terminal, state: state, rect: rect}
  end

  describe "render/2" do
    test "renders header columns", %{terminal: terminal, state: state, rect: rect} do
      widgets = ActionsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Name"
      assert content =~ "Type"
      assert content =~ "Primary?"
      assert content =~ "Arguments"
    end

    test "renders action names", %{terminal: terminal, state: state, rect: rect} do
      widgets = ActionsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "read"
      assert content =~ "create"
      assert content =~ "destroy"
    end

    test "renders action type labels", %{terminal: terminal, state: state, rect: rect} do
      widgets = ActionsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "read"
      assert content =~ "create"
      assert content =~ "destroy"
    end

    test "renders primary action star", %{terminal: terminal, state: state, rect: rect} do
      widgets = ActionsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      # Primary actions show a star
      assert content =~ "\u{2605}"
    end

    test "renders arguments for create action", %{terminal: terminal, state: state, rect: rect} do
      widgets = ActionsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "email"
      assert content =~ "name"
    end

    test "renders empty state when no resource", %{terminal: terminal, rect: rect} do
      state = %State{
        domains: [],
        current_domain: nil,
        current_resource: nil,
        current_tab: :actions
      }

      widgets = ActionsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "No resource selected"
    end

    test "renders update action type for publish", %{terminal: terminal, rect: rect} do
      # Switch to Blog.Post which has a :publish update action
      state =
        Fixtures.sample_domains()
        |> State.new()
        |> State.handle_key("j")
        |> State.handle_key("j")
        |> State.handle_key("j")
        |> State.handle_key("enter")
        |> Map.put(:current_tab, :actions)

      widgets = ActionsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "publish"
      assert content =~ "update"
    end

    test "does not show selection when focus is nav", %{state: state, rect: rect} do
      state = %{state | focus: :nav}
      [{table, _}] = ActionsTab.render(state, rect)
      assert table.selected == nil
    end
  end
end
