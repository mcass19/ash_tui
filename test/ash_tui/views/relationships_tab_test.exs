defmodule AshTui.Views.RelationshipsTabTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Views.RelationshipsTab
  alias AshTui.Test.Fixtures
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Native

  setup do
    terminal = ExRatatui.init_test_terminal(70, 15)
    on_exit(fn -> Native.restore_terminal(terminal) end)
    state = State.new(Fixtures.sample_domains()) |> Map.put(:current_tab, :relationships)
    rect = %Rect{x: 0, y: 0, width: 70, height: 15}
    %{terminal: terminal, state: state, rect: rect}
  end

  describe "render/2" do
    test "renders header columns", %{terminal: terminal, state: state, rect: rect} do
      widgets = RelationshipsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Name"
      assert content =~ "Type"
      assert content =~ "Destination"
    end

    test "renders relationship names", %{terminal: terminal, state: state, rect: rect} do
      widgets = RelationshipsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "posts"
      assert content =~ "tokens"
    end

    test "renders has_many type with arrow", %{terminal: terminal, state: state, rect: rect} do
      widgets = RelationshipsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "has_many"
    end

    test "renders destination short names", %{terminal: terminal, state: state, rect: rect} do
      widgets = RelationshipsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Post"
      assert content =~ "Token"
    end

    test "renders drill-in hint", %{terminal: terminal, state: state, rect: rect} do
      widgets = RelationshipsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "drill in"
    end

    test "renders belongs_to type", %{terminal: terminal, rect: rect} do
      # Navigate to Token which has belongs_to :user
      state =
        Fixtures.sample_domains()
        |> State.new()
        |> State.handle_key("j")
        |> State.handle_key("j")
        |> State.handle_key("enter")
        |> Map.put(:current_tab, :relationships)

      widgets = RelationshipsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "belongs_to"
      assert content =~ "user"
      assert content =~ "User"
    end

    test "renders empty state when no resource", %{state: _state, rect: rect} do
      state = %State{
        domains: [],
        current_domain: nil,
        current_resource: nil,
        current_tab: :relationships
      }

      [{table, _}] = RelationshipsTab.render(state, rect)
      assert [["No resource selected", "", "", ""]] = table.rows
    end

    test "does not show selection when focus is nav", %{state: state, rect: rect} do
      state = %{state | focus: :nav}
      [{table, _}] = RelationshipsTab.render(state, rect)
      assert table.selected == nil
    end
  end
end
