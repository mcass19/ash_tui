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
  alias ExRatatui.Widgets.Block
  alias ExRatatui.Widgets.List, as: WidgetList
  alias ExRatatui.Widgets.Scrollbar
  alias ExRatatui.Widgets.TextInput

  @doc """
  Renders the navigation panel with domain/resource tree and search input.
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

    nav_list = %WidgetList{
      items: list_items,
      selected: state.nav_selected,
      highlight_style: Theme.highlight_style(),
      highlight_symbol: "\u{25B6} ",
      block: %Block{
        title: " Navigation ",
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
          position: state.nav_selected,
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

  defp format_domain(name), do: "\u{25C6} #{Format.short_name(name)}"

  defp format_resource(name), do: "  \u{2514} #{Format.short_name(name)}"
end
