defmodule AshTui.State do
  @moduledoc """
  State struct and pure navigation logic for the Ash TUI explorer.

  All state transitions are pure functions: `handle_key(state, key) -> state`.
  No side effects, no processes — just data transformation.
  """

  alias AshTui.Format

  alias AshTui.Introspection.{
    ActionInfo,
    AttributeInfo,
    DomainInfo,
    RelationshipInfo,
    ResourceInfo
  }

  defstruct [
    :domains,
    :current_domain,
    :current_resource,
    :search_input,
    current_tab: :attributes,
    nav_selected: 0,
    detail_selected: 0,
    focus: :nav,
    nav_stack: [],
    show_help: false,
    detail_overlay: nil,
    searching: false
  ]

  @type tab :: :attributes | :actions | :relationships

  @type t :: %__MODULE__{
          domains: [DomainInfo.t()],
          current_domain: DomainInfo.t() | nil,
          current_resource: ResourceInfo.t() | nil,
          current_tab: tab(),
          nav_selected: non_neg_integer(),
          detail_selected: non_neg_integer(),
          focus: :nav | :detail,
          nav_stack: [{atom(), atom(), tab()}],
          show_help: boolean(),
          detail_overlay: AttributeInfo.t() | nil,
          search_input: reference() | nil,
          searching: boolean()
        }

  @tabs [:attributes, :actions, :relationships]

  @doc """
  Creates a new state from introspection data.

  ## Examples

      iex> domains = AshTui.Introspection.from_data([
      ...>   %{
      ...>     name: MyApp.Accounts,
      ...>     resources: [
      ...>       %{
      ...>         name: MyApp.Accounts.User,
      ...>         attributes: [%{name: :id, type: :uuid, primary_key?: true}],
      ...>         actions: [],
      ...>         relationships: []
      ...>       }
      ...>     ]
      ...>   }
      ...> ])
      iex> state = AshTui.State.new(domains)
      iex> state.current_domain.name
      MyApp.Accounts
      iex> state.current_resource.name
      MyApp.Accounts.User
      iex> state.current_tab
      :attributes

      iex> state = AshTui.State.new([])
      iex> state.current_domain
      nil
  """
  @spec new([DomainInfo.t()]) :: t()
  def new([]) do
    %__MODULE__{domains: [], current_domain: nil, current_resource: nil}
  end

  def new(domains) do
    domain = hd(domains)
    resource = List.first(domain.resources)

    %__MODULE__{
      domains: domains,
      current_domain: domain,
      current_resource: resource
    }
  end

  # ── Navigation Items ────────────────────────────────────────

  @doc """
  Returns the list of items shown in the navigation panel.

  This is a flat list: domain headers followed by their resources
  when the domain is selected/expanded.

  ## Examples

      iex> domains = AshTui.Introspection.from_data([
      ...>   %{
      ...>     name: MyApp.Accounts,
      ...>     resources: [
      ...>       %{
      ...>         name: MyApp.Accounts.User,
      ...>         attributes: [%{name: :id, type: :uuid, primary_key?: true}],
      ...>         actions: [],
      ...>         relationships: []
      ...>       }
      ...>     ]
      ...>   }
      ...> ])
      iex> state = AshTui.State.new(domains)
      iex> items = AshTui.State.nav_items(state)
      iex> [{:domain, domain}, {:resource, resource}] = items
      iex> domain.name
      MyApp.Accounts
      iex> resource.name
      MyApp.Accounts.User
  """
  @spec nav_items(t()) :: [{:domain, DomainInfo.t()} | {:resource, ResourceInfo.t()}]
  def nav_items(%__MODULE__{domains: domains, current_domain: current_domain} = state) do
    query = search_query(state)

    Enum.flat_map(domains, fn domain ->
      domain_item = {:domain, domain}

      if current_domain && domain.name == current_domain.name do
        resource_items =
          domain.resources
          |> maybe_filter_resources(query)
          |> Enum.map(&{:resource, &1})

        [domain_item | resource_items]
      else
        [domain_item]
      end
    end)
  end

  defp search_query(%__MODULE__{search_input: nil}), do: ""

  defp search_query(%__MODULE__{search_input: ref}) do
    ExRatatui.text_input_get_value(ref)
  end

  defp maybe_filter_resources(resources, ""), do: resources

  defp maybe_filter_resources(resources, query) do
    downcased = String.downcase(query)

    Enum.filter(resources, fn resource ->
      resource.name
      |> Format.short_name()
      |> String.downcase()
      |> String.contains?(downcased)
    end)
  end

  @doc """
  Returns the items for the currently active detail tab.

  ## Examples

      iex> domains = AshTui.Introspection.from_data([
      ...>   %{
      ...>     name: MyApp.Accounts,
      ...>     resources: [
      ...>       %{
      ...>         name: MyApp.Accounts.User,
      ...>         attributes: [%{name: :id, type: :uuid, primary_key?: true}],
      ...>         actions: [%{name: :read, type: :read, primary?: true}],
      ...>         relationships: []
      ...>       }
      ...>     ]
      ...>   }
      ...> ])
      iex> state = AshTui.State.new(domains)
      iex> [attr] = AshTui.State.detail_items(state)
      iex> attr.name
      :id

      iex> AshTui.State.detail_items(%AshTui.State{current_resource: nil})
      []
  """
  @spec detail_items(t()) :: [AttributeInfo.t() | ActionInfo.t() | RelationshipInfo.t()]
  def detail_items(%__MODULE__{current_resource: nil}), do: []

  def detail_items(%__MODULE__{current_resource: resource, current_tab: :attributes}) do
    resource.attributes
  end

  def detail_items(%__MODULE__{current_resource: resource, current_tab: :actions}) do
    resource.actions
  end

  def detail_items(%__MODULE__{current_resource: resource, current_tab: :relationships}) do
    resource.relationships
  end

  @doc """
  Returns the breadcrumb trail from the navigation stack.

  ## Examples

      iex> domains = AshTui.Introspection.from_data([
      ...>   %{
      ...>     name: MyApp.Accounts,
      ...>     resources: [
      ...>       %{
      ...>         name: MyApp.Accounts.User,
      ...>         attributes: [%{name: :id, type: :uuid, primary_key?: true}],
      ...>         actions: [],
      ...>         relationships: []
      ...>       }
      ...>     ]
      ...>   }
      ...> ])
      iex> state = AshTui.State.new(domains)
      iex> AshTui.State.breadcrumb(state)
      "User"

      iex> AshTui.State.breadcrumb(AshTui.State.new([]))
      ""
  """
  @spec breadcrumb(t()) :: String.t()
  def breadcrumb(%__MODULE__{nav_stack: [], current_resource: nil}), do: ""

  def breadcrumb(%__MODULE__{nav_stack: [], current_resource: resource}) do
    Format.short_name(resource.name)
  end

  def breadcrumb(%__MODULE__{nav_stack: stack, current_resource: resource}) do
    trail =
      stack
      |> Enum.reverse()
      |> Enum.map(fn {_domain, resource_name, _tab} -> Format.short_name(resource_name) end)

    current = if resource, do: Format.short_name(resource.name), else: ""
    Enum.join(trail ++ [current], " > ")
  end

  # ── Key Handling ─────────────────────────────────────────────

  @doc """
  Processes a key press and returns the updated state.

  Handles vim-style navigation (`j`/`k`/`h`/`l`), tab switching (`tab`, `1`/`2`/`3`),
  enter/esc for selection and back-navigation, `?` for help, and `/` for search.

  ## Examples

      iex> domains = AshTui.Introspection.from_data([
      ...>   %{
      ...>     name: MyApp.Accounts,
      ...>     resources: [
      ...>       %{
      ...>         name: MyApp.Accounts.User,
      ...>         attributes: [%{name: :id, type: :uuid, primary_key?: true}],
      ...>         actions: [],
      ...>         relationships: []
      ...>       }
      ...>     ]
      ...>   }
      ...> ])
      iex> state = AshTui.State.new(domains)
      iex> state = AshTui.State.handle_key(state, "?")
      iex> state.show_help
      true
      iex> state = AshTui.State.handle_key(state, "any")
      iex> state.show_help
      false

      iex> domains = AshTui.Introspection.from_data([
      ...>   %{
      ...>     name: MyApp.Accounts,
      ...>     resources: [
      ...>       %{
      ...>         name: MyApp.Accounts.User,
      ...>         attributes: [%{name: :id, type: :uuid, primary_key?: true}],
      ...>         actions: [],
      ...>         relationships: []
      ...>       }
      ...>     ]
      ...>   }
      ...> ])
      iex> state = AshTui.State.new(domains)
      iex> state = AshTui.State.handle_key(state, "l")
      iex> state.focus
      :detail
      iex> state = AshTui.State.handle_key(state, "h")
      iex> state.focus
      :nav
  """
  @spec handle_key(t(), String.t()) :: t()
  def handle_key(%__MODULE__{show_help: true} = state, _key) do
    %{state | show_help: false}
  end

  def handle_key(%__MODULE__{detail_overlay: overlay} = state, "esc") when not is_nil(overlay) do
    %{state | detail_overlay: nil}
  end

  def handle_key(%__MODULE__{detail_overlay: overlay} = state, _key) when not is_nil(overlay) do
    state
  end

  # Search mode key handling
  def handle_key(%__MODULE__{searching: true} = state, "esc") do
    clear_search(state)
  end

  def handle_key(%__MODULE__{searching: true} = state, "enter") do
    %{state | searching: false, focus: :nav, nav_selected: 0}
  end

  def handle_key(%__MODULE__{searching: true, search_input: ref} = state, key) do
    ExRatatui.text_input_handle_key(ref, key)
    %{state | nav_selected: 0}
  end

  def handle_key(state, "?") do
    %{state | show_help: true}
  end

  def handle_key(state, key) when key in ["j", "down"] do
    move_selection(state, :down)
  end

  def handle_key(state, key) when key in ["k", "up"] do
    move_selection(state, :up)
  end

  def handle_key(state, "enter") do
    handle_enter(state)
  end

  def handle_key(state, "esc") do
    pop_nav_stack(state)
  end

  def handle_key(state, "tab") do
    next_tab(state)
  end

  def handle_key(state, key) when key in ["1", "2", "3"] do
    idx = String.to_integer(key) - 1
    tab = Enum.at(@tabs, idx)
    switch_tab(state, tab)
  end

  def handle_key(state, key) when key in ["h", "left"] do
    %{state | focus: :nav}
  end

  def handle_key(state, key) when key in ["l", "right"] do
    %{state | focus: :detail}
  end

  def handle_key(%__MODULE__{search_input: ref} = state, "/") when not is_nil(ref) do
    %{state | searching: true, focus: :nav}
  end

  def handle_key(state, _key), do: state

  # ── State Transitions ───────────────────────────────────────

  defp move_selection(%{focus: :nav} = state, direction) do
    items = nav_items(state)
    max_idx = max(length(items) - 1, 0)

    new_selected =
      case direction do
        :down -> min(state.nav_selected + 1, max_idx)
        :up -> max(state.nav_selected - 1, 0)
      end

    %{state | nav_selected: new_selected}
  end

  defp move_selection(%{focus: :detail} = state, direction) do
    items = detail_items(state)
    max_idx = max(length(items) - 1, 0)

    new_selected =
      case direction do
        :down -> min(state.detail_selected + 1, max_idx)
        :up -> max(state.detail_selected - 1, 0)
      end

    %{state | detail_selected: new_selected}
  end

  defp handle_enter(%{focus: :nav} = state) do
    items = nav_items(state)

    case Enum.at(items, state.nav_selected) do
      {:domain, domain} ->
        select_domain(state, domain)

      {:resource, resource} ->
        select_resource(state, resource)

      nil ->
        state
    end
  end

  defp handle_enter(%{focus: :detail, current_resource: nil} = state), do: state

  defp handle_enter(%{focus: :detail, current_tab: :attributes} = state) do
    case Enum.at(state.current_resource.attributes, state.detail_selected) do
      %AttributeInfo{} = attr ->
        %{state | detail_overlay: attr}

      nil ->
        state
    end
  end

  defp handle_enter(%{focus: :detail, current_tab: :relationships} = state) do
    case Enum.at(state.current_resource.relationships, state.detail_selected) do
      %RelationshipInfo{} = rel ->
        navigate_to_relationship(state, rel)

      nil ->
        state
    end
  end

  defp handle_enter(state), do: state

  defp select_domain(state, domain) do
    resource = List.first(domain.resources)

    %{state | current_domain: domain, current_resource: resource, detail_selected: 0}
  end

  defp select_resource(state, resource) do
    %{state | current_resource: resource, focus: :detail, detail_selected: 0}
  end

  defp navigate_to_relationship(state, rel) do
    # Push current position onto nav stack
    stack_entry = {state.current_domain.name, state.current_resource.name, state.current_tab}

    # Find the destination resource across all domains
    case find_resource(state.domains, rel.destination) do
      {domain, resource} ->
        %{
          state
          | nav_stack: [stack_entry | state.nav_stack],
            current_domain: domain,
            current_resource: resource,
            current_tab: :attributes,
            detail_selected: 0
        }

      nil ->
        state
    end
  end

  defp pop_nav_stack(%{nav_stack: []} = state), do: state

  defp pop_nav_stack(%{nav_stack: [{domain_name, resource_name, tab} | rest]} = state) do
    case find_resource(state.domains, resource_name) do
      {domain, resource} ->
        %{
          state
          | nav_stack: rest,
            current_domain: domain,
            current_resource: resource,
            current_tab: tab,
            detail_selected: 0
        }

      nil ->
        # Fallback: just find the domain
        domain = Enum.find(state.domains, &(&1.name == domain_name))
        %{state | nav_stack: rest, current_domain: domain, current_tab: tab, detail_selected: 0}
    end
  end

  defp next_tab(state) do
    current_idx = Enum.find_index(@tabs, &(&1 == state.current_tab))
    next_idx = rem(current_idx + 1, length(@tabs))
    switch_tab(state, Enum.at(@tabs, next_idx))
  end

  defp switch_tab(state, tab) when tab in @tabs do
    %{state | current_tab: tab, detail_selected: 0}
  end

  defp clear_search(%__MODULE__{search_input: ref} = state) when not is_nil(ref) do
    ExRatatui.text_input_set_value(ref, "")
    %{state | searching: false, nav_selected: 0}
  end

  defp clear_search(state), do: %{state | searching: false}

  # ── Helpers ──────────────────────────────────────────────────

  defp find_resource(domains, resource_name) do
    Enum.find_value(domains, fn domain ->
      case Enum.find(domain.resources, &(&1.name == resource_name)) do
        nil -> nil
        resource -> {domain, resource}
      end
    end)
  end
end
