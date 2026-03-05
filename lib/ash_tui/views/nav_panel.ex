defmodule AshTui.Views.NavPanel do
  @moduledoc """
  Left panel view: domain list with expanded resources.

  Pure function — takes state and rect, returns `[{widget, rect}]`.
  """

  alias AshTui.Format
  alias AshTui.State
  alias AshTui.Theme
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Widgets.Block
  alias ExRatatui.Widgets.List, as: WidgetList

  @doc """
  Renders the navigation panel with domain/resource tree.
  """
  @spec render(State.t(), Rect.t()) :: [{struct(), Rect.t()}]
  def render(state, rect) do
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
        border_style: Theme.border_style(state.focus == :nav)
      }
    }

    [{nav_list, rect}]
  end

  defp format_domain(name), do: "\u{25C6} #{Format.short_name(name)}"

  defp format_resource(name), do: "  \u{2514} #{Format.short_name(name)}"
end
