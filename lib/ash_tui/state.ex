defmodule AshTui.State do
  @moduledoc """
  State struct and pure navigation logic for the Ash TUI explorer.

  All state transitions are pure functions: `handle_key(state, key) -> state`.
  No side effects, no processes — just data transformation.
  """

  alias AshTui.Introspection.{DomainInfo, RelationshipInfo, ResourceInfo}

  defstruct [
    :domains,
    :current_domain,
    :current_resource,
    current_tab: :attributes,
    nav_selected: 0,
    detail_selected: 0,
    focus: :nav,
    nav_stack: [],
    show_help: false
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
          show_help: boolean()
        }

  @tabs [:attributes, :actions, :relationships]

  @doc """
  Creates a new state from introspection data.
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
  """
  @spec nav_items(t()) :: [{:domain, DomainInfo.t()} | {:resource, ResourceInfo.t()}]
  def nav_items(%__MODULE__{domains: domains, current_domain: current_domain}) do
    Enum.flat_map(domains, fn domain ->
      domain_item = {:domain, domain}

      if current_domain && domain.name == current_domain.name do
        resource_items = Enum.map(domain.resources, &{:resource, &1})
        [domain_item | resource_items]
      else
        [domain_item]
      end
    end)
  end

  @doc """
  Returns the items for the currently active detail tab.
  """
  @spec detail_items(t()) :: [map()]
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
  """
  @spec breadcrumb(t()) :: String.t()
  def breadcrumb(%__MODULE__{nav_stack: [], current_resource: nil}), do: ""

  def breadcrumb(%__MODULE__{nav_stack: [], current_resource: resource}) do
    short_name(resource.name)
  end

  def breadcrumb(%__MODULE__{nav_stack: stack, current_resource: resource}) do
    trail =
      stack
      |> Enum.reverse()
      |> Enum.map(fn {_domain, resource_name, _tab} -> short_name(resource_name) end)

    current = if resource, do: short_name(resource.name), else: ""
    Enum.join(trail ++ [current], " > ")
  end

  # ── Key Handling ─────────────────────────────────────────────

  @doc """
  Processes a key press and returns the updated state.
  """
  @spec handle_key(t(), String.t()) :: t()
  def handle_key(%__MODULE__{show_help: true} = state, _key) do
    %{state | show_help: false}
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

  # ── Helpers ──────────────────────────────────────────────────

  defp find_resource(domains, resource_name) do
    Enum.find_value(domains, fn domain ->
      case Enum.find(domain.resources, &(&1.name == resource_name)) do
        nil -> nil
        resource -> {domain, resource}
      end
    end)
  end

  defp short_name(module) when is_atom(module) do
    module
    |> Module.split()
    |> Elixir.List.last()
  end
end
