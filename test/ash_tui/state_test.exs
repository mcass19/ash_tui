defmodule AshTui.StateTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Test.Fixtures

  setup do
    domains = Fixtures.sample_domains()
    state = State.new(domains)
    %{state: state, domains: domains}
  end

  describe "new/1" do
    test "selects first domain and resource", %{state: state} do
      assert state.current_domain.name == Test.Accounts
      assert state.current_resource.name == Test.Accounts.User
      assert state.current_tab == :attributes
      assert state.focus == :nav
      assert state.nav_stack == []
    end

    test "handles empty domains" do
      state = State.new([])
      assert state.domains == []
      assert state.current_domain == nil
      assert state.current_resource == nil
    end
  end

  describe "nav_items/1" do
    test "returns domains with expanded resources for current domain", %{state: state} do
      items = State.nav_items(state)

      # Accounts is expanded (2 resources), Blog is collapsed
      assert [
               {:domain, _accounts},
               {:resource, _user},
               {:resource, _token},
               {:domain, _blog}
             ] = items
    end

    test "collapses non-selected domains", %{state: state} do
      # Switch to Blog domain
      state = State.handle_key(state, "j") |> State.handle_key("j") |> State.handle_key("j")
      state = State.handle_key(state, "enter")

      items = State.nav_items(state)

      # Blog is now expanded, Accounts is collapsed
      domain_names = for {:domain, d} <- items, do: d.name
      assert Test.Accounts in domain_names
      assert Test.Blog in domain_names

      blog_resources = for {:resource, r} <- items, do: r.name
      assert Test.Blog.Post in blog_resources
    end
  end

  describe "handle_key/2 - navigation" do
    test "j moves selection down in nav", %{state: state} do
      state = State.handle_key(state, "j")
      assert state.nav_selected == 1
    end

    test "k moves selection up in nav", %{state: state} do
      state = state |> State.handle_key("j") |> State.handle_key("j")
      assert state.nav_selected == 2

      state = State.handle_key(state, "k")
      assert state.nav_selected == 1
    end

    test "down arrow works like j", %{state: state} do
      state = State.handle_key(state, "down")
      assert state.nav_selected == 1
    end

    test "up arrow works like k", %{state: state} do
      state = state |> State.handle_key("j") |> State.handle_key("up")
      assert state.nav_selected == 0
    end

    test "selection does not go below zero", %{state: state} do
      state = State.handle_key(state, "k")
      assert state.nav_selected == 0
    end

    test "selection does not exceed item count", %{state: state} do
      # Move way past the end
      state =
        Enum.reduce(1..20, state, fn _i, s ->
          State.handle_key(s, "j")
        end)

      items = State.nav_items(state)
      assert state.nav_selected == length(items) - 1
    end
  end

  describe "handle_key/2 - focus" do
    test "l moves focus to detail", %{state: state} do
      state = State.handle_key(state, "l")
      assert state.focus == :detail
    end

    test "right arrow moves focus to detail", %{state: state} do
      state = State.handle_key(state, "right")
      assert state.focus == :detail
    end

    test "h moves focus to nav", %{state: state} do
      state = %{state | focus: :detail}
      state = State.handle_key(state, "h")
      assert state.focus == :nav
    end

    test "left arrow moves focus to nav", %{state: state} do
      state = %{state | focus: :detail}
      state = State.handle_key(state, "left")
      assert state.focus == :nav
    end
  end

  describe "handle_key/2 - tabs" do
    test "tab cycles through tabs", %{state: state} do
      assert state.current_tab == :attributes

      state = State.handle_key(state, "tab")
      assert state.current_tab == :actions

      state = State.handle_key(state, "tab")
      assert state.current_tab == :relationships

      state = State.handle_key(state, "tab")
      assert state.current_tab == :attributes
    end

    test "number keys jump to tabs", %{state: state} do
      state = State.handle_key(state, "2")
      assert state.current_tab == :actions

      state = State.handle_key(state, "3")
      assert state.current_tab == :relationships

      state = State.handle_key(state, "1")
      assert state.current_tab == :attributes
    end

    test "switching tabs resets detail selection", %{state: state} do
      state = %{state | focus: :detail, detail_selected: 2}
      state = State.handle_key(state, "tab")
      assert state.detail_selected == 0
    end
  end

  describe "handle_key/2 - enter" do
    test "enter on domain selects it", %{state: state} do
      # Move to Blog domain (index 3 in nav items)
      state =
        state
        |> State.handle_key("j")
        |> State.handle_key("j")
        |> State.handle_key("j")

      state = State.handle_key(state, "enter")
      assert state.current_domain.name == Test.Blog
    end

    test "enter on resource selects it and focuses detail", %{state: state} do
      # Move to Token (index 2 in nav items)
      state = state |> State.handle_key("j") |> State.handle_key("j")
      state = State.handle_key(state, "enter")

      assert state.current_resource.name == Test.Accounts.Token
      assert state.focus == :detail
    end
  end

  describe "relationship navigation" do
    test "enter on relationship navigates to destination", %{state: state} do
      # Set up: focus detail, switch to relationships tab
      state = %{state | focus: :detail, current_tab: :relationships}

      # Enter on first relationship (posts -> Blog.Post)
      state = State.handle_key(state, "enter")

      assert state.current_resource.name == Test.Blog.Post
      assert state.current_domain.name == Test.Blog
      assert state.current_tab == :attributes
      assert length(state.nav_stack) == 1
    end

    test "esc pops nav stack", %{state: state} do
      # Navigate to a relationship first
      state = %{state | focus: :detail, current_tab: :relationships}
      state = State.handle_key(state, "enter")

      assert state.current_resource.name == Test.Blog.Post

      # Pop back
      state = State.handle_key(state, "esc")
      assert state.current_resource.name == Test.Accounts.User
      assert state.current_domain.name == Test.Accounts
      assert state.nav_stack == []
    end

    test "esc on empty nav stack is a no-op", %{state: state} do
      state = State.handle_key(state, "esc")
      assert state.nav_stack == []
      assert state.current_resource.name == Test.Accounts.User
    end
  end

  describe "breadcrumb/1" do
    test "shows resource name with no stack", %{state: state} do
      assert State.breadcrumb(state) == "User"
    end

    test "shows trail with navigation stack", %{state: state} do
      state = %{state | focus: :detail, current_tab: :relationships}
      state = State.handle_key(state, "enter")

      assert State.breadcrumb(state) == "User > Post"
    end

    test "empty when no resource selected" do
      state = State.new([])
      assert State.breadcrumb(state) == ""
    end
  end

  describe "detail_items/1" do
    test "returns attributes for attributes tab", %{state: state} do
      items = State.detail_items(state)
      assert length(items) == 4
      names = Enum.map(items, & &1.name)
      assert :email in names
    end

    test "returns actions for actions tab", %{state: state} do
      state = %{state | current_tab: :actions}
      items = State.detail_items(state)
      assert length(items) == 3
      names = Enum.map(items, & &1.name)
      assert :create in names
    end

    test "returns relationships for relationships tab", %{state: state} do
      state = %{state | current_tab: :relationships}
      items = State.detail_items(state)
      assert length(items) == 2
      names = Enum.map(items, & &1.name)
      assert :posts in names
    end

    test "returns empty list when no resource", %{state: _state} do
      state = State.new([])
      assert State.detail_items(state) == []
    end
  end

  describe "handle_key/2 - help" do
    test "? toggles help on", %{state: state} do
      state = State.handle_key(state, "?")
      assert state.show_help == true
    end

    test "any key dismisses help", %{state: state} do
      state = %{state | show_help: true}
      state = State.handle_key(state, "j")
      assert state.show_help == false
    end
  end
end
