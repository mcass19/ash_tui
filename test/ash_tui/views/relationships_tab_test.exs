defmodule AshTui.Views.RelationshipsTabTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Views.RelationshipsTab
  alias AshTui.Test.Fixtures
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Native

  doctest AshTui.Views.RelationshipsTab

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

    test "renders has_one type", %{terminal: terminal, rect: rect} do
      domains =
        AshTui.Introspection.from_data([
          %{
            name: Test.HasOne,
            resources: [
              %{
                name: Test.HasOne.User,
                attributes: [],
                actions: [],
                relationships: [
                  %{name: :profile, type: :has_one, destination: Test.HasOne.Profile}
                ]
              }
            ]
          }
        ])

      state = State.new(domains) |> Map.put(:current_tab, :relationships)
      widgets = RelationshipsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "has_one"
    end

    test "renders many_to_many type", %{terminal: terminal, rect: rect} do
      domains =
        AshTui.Introspection.from_data([
          %{
            name: Test.M2M,
            resources: [
              %{
                name: Test.M2M.Post,
                attributes: [],
                actions: [],
                relationships: [
                  %{name: :tags, type: :many_to_many, destination: Test.M2M.Tag}
                ]
              }
            ]
          }
        ])

      state = State.new(domains) |> Map.put(:current_tab, :relationships)
      widgets = RelationshipsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "many_to_many"
    end

    test "renders unknown relationship type as string", %{terminal: terminal, rect: rect} do
      domains =
        AshTui.Introspection.from_data([
          %{
            name: Test.Unknown,
            resources: [
              %{
                name: Test.Unknown.Item,
                attributes: [],
                actions: [],
                relationships: [
                  %{name: :custom, type: :custom_type, destination: Test.Unknown.Other}
                ]
              }
            ]
          }
        ])

      state = State.new(domains) |> Map.put(:current_tab, :relationships)
      widgets = RelationshipsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "custom_type"
    end

    test "does not show selection when focus is nav", %{state: state, rect: rect} do
      state = %{state | focus: :nav}
      [{table, _}] = RelationshipsTab.render(state, rect)
      assert table.selected == nil
    end

    test "renders scrollbar when rows exceed viewport", %{terminal: terminal} do
      rels =
        for i <- 1..10,
            do: %{name: :"rel_#{i}", type: :has_many, destination: Test.Scroll.Target}

      domains =
        AshTui.Introspection.from_data([
          %{
            name: Test.Scroll,
            resources: [
              %{name: Test.Scroll.Item, attributes: [], actions: [], relationships: rels}
            ]
          }
        ])

      state = State.new(domains) |> Map.merge(%{current_tab: :relationships, focus: :detail})
      rect = %Rect{x: 0, y: 0, width: 70, height: 6}
      widgets = RelationshipsTab.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "rel_1"
    end
  end
end
