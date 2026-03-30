defmodule AshTui.StateTest do
  use ExUnit.Case, async: true

  alias AshTui.State
  alias AshTui.Test.Fixtures

  doctest AshTui.State

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

    test "handles domain with zero resources" do
      domains =
        AshTui.Introspection.from_data([
          %{name: Test.Empty, resources: []}
        ])

      state = State.new(domains)
      assert state.current_domain.name == Test.Empty
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

  describe "handle_key/2 - detail navigation" do
    test "j/k in detail panel moves detail_selected", %{state: state} do
      state = %{state | focus: :detail}
      state = State.handle_key(state, "j")
      assert state.detail_selected == 1

      state = State.handle_key(state, "k")
      assert state.detail_selected == 0
    end

    test "detail selection clamped to 0 when no items", %{state: _state} do
      empty_state = State.new([])
      state = %{empty_state | focus: :detail}
      state = State.handle_key(state, "j")
      assert state.detail_selected == 0
    end

    test "enter on actions tab is a no-op", %{state: state} do
      state = %{state | focus: :detail, current_tab: :actions}
      new_state = State.handle_key(state, "enter")
      assert new_state == state
    end
  end

  describe "handle_key/2 - multi-level navigation" do
    test "drill 2 levels deep via relationships", %{state: state} do
      # User -> posts -> Post -> author -> User
      state = %{state | focus: :detail, current_tab: :relationships}
      state = State.handle_key(state, "enter")
      assert state.current_resource.name == Test.Blog.Post
      assert length(state.nav_stack) == 1

      state = %{state | current_tab: :relationships}
      state = State.handle_key(state, "enter")
      assert state.current_resource.name == Test.Accounts.User
      assert length(state.nav_stack) == 2
    end

    test "esc unwinds 2 levels back", %{state: state} do
      state = %{state | focus: :detail, current_tab: :relationships}
      state = State.handle_key(state, "enter")
      state = %{state | current_tab: :relationships}
      state = State.handle_key(state, "enter")
      assert length(state.nav_stack) == 2

      state = State.handle_key(state, "esc")
      assert state.current_resource.name == Test.Blog.Post
      assert length(state.nav_stack) == 1

      state = State.handle_key(state, "esc")
      assert state.current_resource.name == Test.Accounts.User
      assert state.nav_stack == []
    end
  end

  describe "handle_key/2 - unknown keys" do
    test "unknown key is a no-op", %{state: state} do
      assert State.handle_key(state, "x") == state
    end
  end

  describe "handle_key/2 - attribute detail overlay" do
    test "enter on attributes tab opens detail overlay", %{state: state} do
      state = %{state | focus: :detail, current_tab: :attributes}
      state = State.handle_key(state, "enter")

      assert state.detail_overlay != nil
      assert state.detail_overlay.name == :id
    end

    test "enter on second attribute opens correct detail", %{state: state} do
      state = %{state | focus: :detail, current_tab: :attributes, detail_selected: 1}
      state = State.handle_key(state, "enter")

      assert state.detail_overlay.name == :email
    end

    test "esc dismisses the detail overlay", %{state: state} do
      state = %{state | focus: :detail, current_tab: :attributes}
      state = State.handle_key(state, "enter")
      assert state.detail_overlay != nil

      state = State.handle_key(state, "esc")
      assert state.detail_overlay == nil
    end

    test "other keys are ignored while overlay is open", %{state: state} do
      state = %{state | focus: :detail, current_tab: :attributes}
      state = State.handle_key(state, "enter")
      original = state

      # These should all be no-ops
      assert State.handle_key(state, "j") == original
      assert State.handle_key(state, "k") == original
      assert State.handle_key(state, "tab") == original
      assert State.handle_key(state, "h") == original
      assert State.handle_key(state, "?") == original
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

  describe "handle_key/2 - search mode" do
    setup %{state: state} do
      ref = ExRatatui.text_input_new()
      %{state: %{state | search_input: ref}}
    end

    test "/ activates search mode", %{state: state} do
      state = State.handle_key(state, "/")
      assert state.searching == true
      assert state.focus == :nav
    end

    test "enter in search mode exits searching", %{state: state} do
      state = %{state | searching: true}
      state = State.handle_key(state, "enter")
      assert state.searching == false
      assert state.focus == :nav
      assert state.nav_selected == 0
    end

    test "esc in search mode clears search text", %{state: state} do
      ExRatatui.text_input_handle_key(state.search_input, "t")
      state = %{state | searching: true}
      state = State.handle_key(state, "esc")
      assert state.searching == false
      assert state.nav_selected == 0
      assert ExRatatui.text_input_get_value(state.search_input) == ""
    end

    test "typing in search mode delegates to text input", %{state: state} do
      state = %{state | searching: true}
      state = State.handle_key(state, "a")
      assert state.nav_selected == 0
      assert ExRatatui.text_input_get_value(state.search_input) == "a"
    end

    test "search filters nav items by resource name", %{state: state} do
      ExRatatui.text_input_set_value(state.search_input, "tok")
      items = State.nav_items(state)
      resource_names = for {:resource, r} <- items, do: r.name
      assert Test.Accounts.Token in resource_names
      refute Test.Accounts.User in resource_names
    end
  end

  describe "handle_key/2 - search mode without ref" do
    test "esc in search mode with nil search_input resets searching" do
      state = %State{
        domains: [],
        current_domain: nil,
        current_resource: nil,
        searching: true,
        search_input: nil
      }

      state = State.handle_key(state, "esc")
      assert state.searching == false
    end
  end

  describe "breadcrumb/1 - edge cases" do
    test "shows trail without current when resource is nil", %{state: state} do
      state = %{
        state
        | nav_stack: [{Test.Accounts, Test.Accounts.User, :attributes}],
          current_resource: nil
      }

      assert State.breadcrumb(state) == "User > "
    end
  end

  describe "pop_nav_stack - fallback" do
    test "falls back to domain when resource not found in stack", %{state: state} do
      state = %{state | nav_stack: [{Test.Accounts, Test.NonExistent, :actions}]}
      state = State.handle_key(state, "esc")
      assert state.current_domain.name == Test.Accounts
      assert state.current_tab == :actions
      assert state.nav_stack == []
    end
  end

  describe "handle_key/2 - edge cases" do
    test "enter in detail focus with nil resource is a no-op" do
      state = %State{
        domains: [],
        current_domain: nil,
        current_resource: nil,
        focus: :detail,
        current_tab: :attributes
      }

      assert State.handle_key(state, "enter") == state
    end

    test "enter on nav with out-of-bounds selection is a no-op", %{state: state} do
      state = %{state | nav_selected: 999}
      new_state = State.handle_key(state, "enter")
      assert new_state.nav_selected == 999
    end

    test "enter on attributes with out-of-bounds selection is a no-op", %{state: state} do
      state = %{state | focus: :detail, current_tab: :attributes, detail_selected: 999}
      new_state = State.handle_key(state, "enter")
      assert new_state.detail_overlay == nil
    end

    test "enter on relationships with out-of-bounds selection is a no-op", %{state: state} do
      state = %{state | focus: :detail, current_tab: :relationships, detail_selected: 999}
      new_state = State.handle_key(state, "enter")
      assert new_state.nav_stack == []
    end

    test "enter on relationship with non-existent destination is a no-op", %{state: state} do
      alias AshTui.Introspection.{RelationshipInfo, ResourceInfo}

      # Create a resource with a relationship pointing to a non-existent module
      fake_resource = %ResourceInfo{
        name: Test.Fake,
        domain: Test.Accounts,
        relationships: [
          %RelationshipInfo{name: :ghost, type: :belongs_to, destination: Test.NonExistent}
        ],
        attributes: [],
        actions: []
      }

      state = %{
        state
        | current_resource: fake_resource,
          focus: :detail,
          current_tab: :relationships
      }

      new_state = State.handle_key(state, "enter")

      # Should be unchanged since destination doesn't exist
      assert new_state.current_resource.name == Test.Fake
      assert new_state.nav_stack == []
    end
  end
end
