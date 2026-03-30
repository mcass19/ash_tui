defmodule AshTui.AppTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Test.Fixtures
  alias ExRatatui.Native

  setup do
    terminal = ExRatatui.init_test_terminal(100, 30)
    on_exit(fn -> Native.restore_terminal(terminal) end)
    state = State.new(Fixtures.sample_domains())
    %{terminal: terminal, state: state}
  end

  defp render_app(terminal, state) do
    frame = %ExRatatui.Frame{width: 100, height: 30}
    widgets = AshTui.App.render(state, frame)
    :ok = ExRatatui.draw(terminal, widgets)
    ExRatatui.get_buffer_content(terminal)
  end

  describe "render/2 - full layout" do
    test "renders header with title", %{terminal: terminal, state: state} do
      content = render_app(terminal, state)
      assert content =~ "Ash TUI Explorer"
    end

    test "renders header with breadcrumb", %{terminal: terminal, state: state} do
      content = render_app(terminal, state)
      assert content =~ "User"
    end

    test "renders navigation panel", %{terminal: terminal, state: state} do
      content = render_app(terminal, state)
      assert content =~ "Navigation"
      assert content =~ "Accounts"
    end

    test "renders tab bar with resource name", %{terminal: terminal, state: state} do
      content = render_app(terminal, state)
      assert content =~ "Accounts.User"
      assert content =~ "Attributes"
    end

    test "renders attributes table content", %{terminal: terminal, state: state} do
      content = render_app(terminal, state)
      assert content =~ "email"
      assert content =~ "ci_string"
    end

    test "renders footer with keybindings", %{terminal: terminal, state: state} do
      content = render_app(terminal, state)
      assert content =~ "navigate"
      assert content =~ "select"
      assert content =~ "quit"
    end

    test "footer shows hjkl hints", %{terminal: terminal, state: state} do
      content = render_app(terminal, state)
      assert content =~ "j/k/"
      assert content =~ "h/l/"
    end

    test "footer shows Esc when in detail mode", %{terminal: terminal, state: state} do
      state = %{state | focus: :detail}
      content = render_app(terminal, state)
      assert content =~ "Esc"
    end
  end

  describe "render/2 - tabs" do
    test "renders actions tab content", %{terminal: terminal, state: state} do
      state = %{state | current_tab: :actions}
      content = render_app(terminal, state)
      assert content =~ "read"
      assert content =~ "create"
    end

    test "renders relationships tab content", %{terminal: terminal, state: state} do
      state = %{state | current_tab: :relationships}
      content = render_app(terminal, state)
      assert content =~ "posts"
      assert content =~ "has_many"
    end

    test "active tab is shown", %{terminal: terminal, state: state} do
      content = render_app(terminal, state)
      assert content =~ "Attributes"
      assert content =~ "Actions"
      assert content =~ "Relationships"
    end
  end

  describe "render/2 - help overlay" do
    test "shows help text when help is active", %{terminal: terminal, state: state} do
      state = %{state | show_help: true}
      content = render_app(terminal, state)
      assert content =~ "Keyboard Reference"
      assert content =~ "Move selection down"
      assert content =~ "Help"
    end
  end

  describe "render/2 - attribute detail overlay" do
    test "shows overlay on top of layout", %{terminal: terminal, state: state} do
      attr = hd(state.current_resource.attributes)
      state = %{state | detail_overlay: attr, focus: :detail}
      content = render_app(terminal, state)

      # Both the underlying layout and the overlay should render
      assert content =~ "Navigation"
      assert content =~ "Attribute: id"
    end
  end

  describe "render/2 - no resource selected" do
    test "renders without breadcrumb", %{terminal: terminal} do
      state = State.new([])
      frame = %ExRatatui.Frame{width: 100, height: 30}
      widgets = AshTui.App.render(state, frame)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Ash TUI Explorer"
      assert content =~ "No resource selected"
    end
  end

  describe "handle_event/2" do
    test "q stops the app", %{state: state} do
      event = %ExRatatui.Event.Key{code: "q", kind: "press"}
      assert {:stop, ^state} = AshTui.App.handle_event(event, state)
    end

    test "q does not stop when help is shown", %{state: state} do
      state = %{state | show_help: true}
      event = %ExRatatui.Event.Key{code: "q", kind: "press"}
      {:noreply, new_state} = AshTui.App.handle_event(event, state)
      assert new_state.show_help == false
    end

    test "key press delegates to State.handle_key", %{state: state} do
      event = %ExRatatui.Event.Key{code: "j", kind: "press"}
      {:noreply, new_state} = AshTui.App.handle_event(event, state)
      assert new_state.nav_selected == 1
    end

    test "q does not stop when detail overlay is open", %{state: state} do
      attr = hd(state.current_resource.attributes)
      state = %{state | detail_overlay: attr, focus: :detail}
      event = %ExRatatui.Event.Key{code: "q", kind: "press"}
      {:noreply, new_state} = AshTui.App.handle_event(event, state)
      # q is a no-op while overlay is open (keys other than Esc are ignored)
      assert new_state.detail_overlay == attr
    end

    test "q does not stop when searching", %{state: state} do
      ref = ExRatatui.text_input_new()
      state = %{state | searching: true, search_input: ref}
      event = %ExRatatui.Event.Key{code: "q", kind: "press"}
      {:noreply, new_state} = AshTui.App.handle_event(event, state)
      # q in search mode is sent to text input, not treated as quit
      assert new_state.nav_selected == 0
    end

    test "non-key events are ignored", %{state: state} do
      {:noreply, ^state} = AshTui.App.handle_event(:some_other_event, state)
    end
  end

  describe "render/2 - footer modes" do
    test "footer shows search hints when in search mode", %{terminal: terminal, state: state} do
      state = %{state | searching: true}
      content = render_app(terminal, state)
      assert content =~ "filter"
      assert content =~ "confirm"
      assert content =~ "cancel"
    end
  end

  describe "terminate/2" do
    test "returns :ok" do
      assert :ok = AshTui.App.terminate(:normal, %{})
    end
  end
end
