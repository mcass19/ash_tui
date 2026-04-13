defmodule AshTui.Views.AttributesTabTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Test.Fixtures
  alias AshTui.Views.AttributesTab
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Native

  doctest AshTui.Views.AttributesTab

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

    test "renders primary key only indicator (not generated)", %{terminal: terminal, rect: rect} do
      domains =
        AshTui.Introspection.from_data([
          %{
            name: Test.PKOnly,
            resources: [
              %{
                name: Test.PKOnly.Item,
                attributes: [
                  %{name: :id, type: :integer, primary_key?: true, generated?: false}
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

      # Primary key without generated shows just the key emoji (no "auto")
      assert content =~ "\u{1F511}"
      refute content =~ "auto"
    end

    test "renders generated only indicator (not primary key)", %{terminal: terminal, rect: rect} do
      domains =
        AshTui.Introspection.from_data([
          %{
            name: Test.GenOnly,
            resources: [
              %{
                name: Test.GenOnly.Item,
                attributes: [
                  %{
                    name: :inserted_at,
                    type: :utc_datetime,
                    generated?: true,
                    primary_key?: false
                  }
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

      assert content =~ "\u{2699}"
      assert content =~ "auto"
    end

    test "renders scrollbar when rows exceed viewport", %{terminal: terminal} do
      attrs = for i <- 1..20, do: %{name: :"field_#{i}", type: :string}

      domains =
        AshTui.Introspection.from_data([
          %{
            name: Test.Many,
            resources: [
              %{name: Test.Many.Item, attributes: attrs, actions: [], relationships: []}
            ]
          }
        ])

      state = State.new(domains) |> Map.put(:focus, :detail)
      rect = %Rect{x: 0, y: 0, width: 60, height: 8}
      widgets = AttributesTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "field_1"
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
