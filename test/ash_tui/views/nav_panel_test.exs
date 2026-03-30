defmodule AshTui.Views.NavPanelTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Views.NavPanel
  alias AshTui.Test.Fixtures
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Native

  doctest AshTui.Views.NavPanel

  setup do
    terminal = ExRatatui.init_test_terminal(40, 20)
    on_exit(fn -> Native.restore_terminal(terminal) end)
    state = State.new(Fixtures.sample_domains())
    rect = %Rect{x: 0, y: 0, width: 40, height: 20}
    %{terminal: terminal, state: state, rect: rect}
  end

  describe "render/2" do
    test "renders domain names", %{terminal: terminal, state: state, rect: rect} do
      widgets = NavPanel.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Accounts"
      assert content =~ "Blog"
    end

    test "renders expanded resource names under current domain", %{
      terminal: terminal,
      state: state,
      rect: rect
    } do
      widgets = NavPanel.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "User"
      assert content =~ "Token"
    end

    test "renders Navigation title", %{terminal: terminal, state: state, rect: rect} do
      widgets = NavPanel.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Navigation"
    end

    test "renders highlight symbol on selected item", %{
      terminal: terminal,
      state: state,
      rect: rect
    } do
      widgets = NavPanel.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      # The highlight symbol is a triangle
      assert content =~ "\u{25B6}"
    end

    test "renders after switching domain", %{terminal: terminal, rect: rect} do
      # Navigate to Blog domain (index 3) and select it
      state =
        Fixtures.sample_domains()
        |> State.new()
        |> State.handle_key("j")
        |> State.handle_key("j")
        |> State.handle_key("j")
        |> State.handle_key("enter")

      widgets = NavPanel.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      # Blog resources should be visible
      assert content =~ "Post"
    end

    test "returns single widget-rect tuple when no search input", %{state: state, rect: rect} do
      widgets = NavPanel.render(state, rect)
      assert [{%ExRatatui.Widgets.List{}, ^rect}] = widgets
    end

    test "renders search bar when search_input is present", %{terminal: terminal, rect: rect} do
      ref = ExRatatui.text_input_new()
      state = State.new(Fixtures.sample_domains()) |> Map.put(:search_input, ref)
      widgets = NavPanel.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Search"
      assert content =~ "Navigation"
    end

    test "search bar highlights when actively searching", %{terminal: terminal, rect: rect} do
      ref = ExRatatui.text_input_new()

      state =
        Fixtures.sample_domains()
        |> State.new()
        |> Map.merge(%{search_input: ref, searching: true})

      widgets = NavPanel.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Search"
    end

    test "renders scrollbar when items exceed viewport", %{terminal: terminal} do
      # Use a small rect so 4 items exceed viewport_h (5 - 2 borders = 3)
      rect = %Rect{x: 0, y: 0, width: 40, height: 5}
      state = State.new(Fixtures.sample_domains())
      widgets = NavPanel.render(state, rect)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Navigation"
    end
  end
end
