defmodule AshTui.Views.NavPanel do
  @moduledoc """
  Left panel view: domain list with expanded resources.

  Pure function — takes state and rect, returns `[{widget, rect}]`.
  """

  alias AshTui.State
  alias ExRatatui.Layout
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, List, Paragraph}

  @doc """
  Renders the navigation panel with domain/resource list and footer hints.
  """
  @spec render(State.t(), Rect.t()) :: [{struct(), Rect.t()}]
  def render(state, rect) do
    [list_area, footer_area] =
      Layout.split(rect, :vertical, [
        {:min, 0},
        {:length, 1}
      ])

    items = State.nav_items(state)

    list_items =
      Enum.map(items, fn
        {:domain, domain} -> format_domain(domain.name)
        {:resource, resource} -> format_resource(resource.name)
      end)

    border_style =
      if state.focus == :nav do
        %Style{fg: {:rgb, 100, 149, 237}}
      else
        %Style{fg: {:rgb, 60, 60, 80}}
      end

    nav_list = %List{
      items: list_items,
      selected: state.nav_selected,
      highlight_style: %Style{fg: {:rgb, 255, 215, 0}, modifiers: [:bold]},
      highlight_symbol: " > ",
      block: %Block{
        title: " Navigation ",
        borders: [:all],
        border_type: :rounded,
        border_style: border_style
      }
    }

    footer = %Paragraph{
      text: " q:quit  ?:help",
      style: %Style{fg: {:rgb, 100, 100, 120}}
    }

    [{nav_list, list_area}, {footer, footer_area}]
  end

  defp format_domain(name) do
    short = name |> Module.split() |> Elixir.List.last()
    short
  end

  defp format_resource(name) do
    short = name |> Module.split() |> Elixir.List.last()
    "  #{short}"
  end
end
