defmodule AshTui.Views.AttributesTabTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Views.AttributesTab
  alias AshTui.Test.Fixtures
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Native

  setup do
    terminal = ExRatatui.init_test_terminal(60, 15)
    on_exit(fn -> Native.restore_terminal(terminal) end)
    state = State.new(Fixtures.sample_domains())
    rect = %Rect{x: 0, y: 0, width: 60, height: 15}
    %{terminal: terminal, state: state, rect: rect}
  end

  describe "render/2" do
    test "renders header columns", %{terminal: terminal, state: state, rect: rect} do
      widgets = AttributesTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Name"
      assert content =~ "Type"
      assert content =~ "Required?"
    end

    test "renders attribute names", %{terminal: terminal, state: state, rect: rect} do
      widgets = AttributesTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "id"
      assert content =~ "email"
      assert content =~ "name"
      assert content =~ "role"
    end

    test "renders attribute types", %{terminal: terminal, state: state, rect: rect} do
      widgets = AttributesTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "uuid"
      assert content =~ "ci_string"
      assert content =~ "string"
      assert content =~ "atom"
    end

    test "renders required status indicators", %{terminal: terminal, state: state, rect: rect} do
      widgets = AttributesTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      # Primary key auto-generated shows key+auto
      assert content =~ "\u{1F511}"
      # Required (allow_nil?: false) shows check
      assert content =~ "\u{2713}"
    end

    test "renders empty state when no resource selected", %{terminal: terminal, rect: rect} do
      state = %State{
        domains: [],
        current_domain: nil,
        current_resource: nil,
        current_tab: :attributes
      }

      widgets = AttributesTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "No resource selected"
    end

    test "does not show selection when focus is nav", %{state: state, rect: rect} do
      state = %{state | focus: :nav}
      [{table, _}] = AttributesTab.render(state, rect)
      assert table.selected == nil
    end

    test "shows selection when focus is detail", %{state: state, rect: rect} do
      state = %{state | focus: :detail, detail_selected: 2}
      [{table, _}] = AttributesTab.render(state, rect)
      assert table.selected == 2
    end

    test "formats array types", %{terminal: terminal, rect: rect} do
      domains =
        AshTui.Introspection.from_data([
          %{
            name: Test.ArrayDomain,
            resources: [
              %{
                name: Test.ArrayDomain.Item,
                attributes: [
                  %{name: :tags, type: {:array, :string}}
                ],
                actions: [],
                relationships: []
              }
            ]
          }
        ])

      state = State.new(domains)
      widgets = AttributesTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "[string]"
    end
  end
end
