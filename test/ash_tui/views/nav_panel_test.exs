defmodule AshTui.Views.NavPanelTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Views.NavPanel
  alias AshTui.Test.Fixtures
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Native

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

    test "returns single widget-rect tuple", %{state: state, rect: rect} do
      widgets = NavPanel.render(state, rect)
      assert [{%ExRatatui.Widgets.List{}, ^rect}] = widgets
    end
  end
end
