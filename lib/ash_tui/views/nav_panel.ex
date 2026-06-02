defmodule AshTui.Views.NavPanel do
  @moduledoc """
  Left panel view: domain list with expanded resources, with optional search.

  Pure function — takes state and rect, returns `[{widget, rect}]`.
  """

  alias AshTui.Format
  alias AshTui.State
  alias AshTui.Theme
  alias ExRatatui.Layout
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Text.{Line, Span}
  alias ExRatatui.Widgets.Block
  alias ExRatatui.Widgets.List, as: WidgetList
  alias ExRatatui.Widgets.Scrollbar
  alias ExRatatui.Widgets.TextInput

  @doc """
  Renders the navigation panel with domain/resource tree and search input.

  Returns a list of `{widget, rect}` tuples containing the navigation list
  (and optionally a scrollbar and search input).

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
      iex> rect = %ExRatatui.Layout.Rect{x: 0, y: 0, width: 30, height: 20}
      iex> [{%ExRatatui.Widgets.List{}, ^rect}] = AshTui.Views.NavPanel.render(state, rect)
  """
  @spec render(State.t(), Rect.t()) :: [{struct(), Rect.t()}]
  def render(%{search_input: nil} = state, rect) do
    render_list(state, rect)
  end

  def render(state, rect) do
    [search_area, list_area] =
      Layout.split(rect, :vertical, [
        {:length, 3},
        {:min, 0}
      ])

    search_widgets = render_search(state, search_area)
    list_widgets = render_list(state, list_area)

    search_widgets ++ list_widgets
  end

  defp render_search(state, rect) do
    border_style =
      if state.searching,
        do: %Style{fg: Theme.gold()},
        else: Theme.unfocused_border_style()

    input = %TextInput{
      state: state.search_input,
      style: %Style{fg: :white},
      cursor_style: %Style{fg: :black, bg: :white},
      placeholder: "/ search...",
      placeholder_style: %Style{fg: Theme.dim_text()},
      block: %Block{
        title: " Search ",
        borders: [:all],
        border_type: :rounded,
        border_style: border_style
      }
    }

    [{input, rect}]
  end

  defp render_list(state, rect) do
    items = State.nav_items(state)

    list_items =
      Enum.map(items, fn
        {:domain, domain} -> format_domain(domain.name)
        {:resource, resource} -> format_resource(resource.name)
      end)

    selected = clamp_selected(state.nav_selected, length(list_items))

    nav_list = %WidgetList{
      items: list_items,
      selected: selected,
      highlight_style: Theme.highlight_style(),
      highlight_symbol: "\u{25B6} ",
      block: %Block{
        title: nav_title(state),
        borders: [:all],
        border_type: :rounded,
        border_style: Theme.border_style(state.focus == :nav and not state.searching)
      }
    }

    # Scrollbar: viewport height is rect height minus 2 for borders
    viewport_h = max(rect.height - 2, 1)
    item_count = length(list_items)

    scrollbar_widgets =
      if item_count > viewport_h do
        scrollbar = %Scrollbar{
          orientation: :vertical_right,
          content_length: item_count,
          position: selected || 0,
          viewport_content_length: viewport_h,
          thumb_style: %Style{fg: Theme.cornflower()},
          track_style: %Style{fg: Theme.dim_border()}
        }

        [{scrollbar, rect}]
      else
        []
      end

    [{nav_list, rect}] ++ scrollbar_widgets
  end

  # ex_ratatui 0.10 validates that a List's `selected` is nil or in range.
  # `nav_selected` can fall outside the visible list — an empty app (no
  # domains) or a list that shrinks when domains collapse / search filters —
  # so reconcile the desired index against the rendered rows here, matching
  # ratatui's own prior clamp-to-range behaviour.
  defp clamp_selected(_index, 0), do: nil
  defp clamp_selected(index, count), do: min(index, count - 1)

  defp format_domain(name), do: "\u{25C6} #{Format.short_name(name)}"

  defp format_resource(name), do: "  \u{2514} #{Format.short_name(name)}"

  defp nav_title(state) do
    domain_count = length(state.domains)
    resource_count = state.domains |> Enum.flat_map(& &1.resources) |> length()

    %Line{
      spans: [
        %Span{content: " Navigation ", style: %Style{fg: Theme.cornflower(), modifiers: [:bold]}},
        %Span{
          content: to_string(domain_count),
          style: %Style{fg: Theme.gold(), modifiers: [:bold]}
        },
        %Span{content: "d · ", style: %Style{fg: Theme.dim_text()}},
        %Span{
          content: to_string(resource_count),
          style: %Style{fg: Theme.gold(), modifiers: [:bold]}
        },
        %Span{content: "r ", style: %Style{fg: Theme.dim_text()}}
      ]
    }
  end
end
