defmodule AshTui.Views.NavPanel do
  @moduledoc """
  Left panel view: domain list with expanded resources.

  Pure function — takes state and rect, returns `[{widget, rect}]`.
  """

  alias AshTui.State
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, List}

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

    border_style =
      if state.focus == :nav do
        %Style{fg: {:rgb, 100, 149, 237}}
      else
        %Style{fg: {:rgb, 60, 60, 80}}
      end

    nav_list = %List{
      items: list_items,
      selected: state.nav_selected,
      highlight_style: %Style{
        fg: {:rgb, 255, 215, 0},
        bg: {:rgb, 40, 40, 60},
        modifiers: [:bold]
      },
      highlight_symbol: "\u{25B6} ",
      block: %Block{
        title: " Navigation ",
        borders: [:all],
        border_type: :rounded,
        border_style: border_style
      }
    }

    [{nav_list, rect}]
  end

  defp format_domain(name) do
    short = name |> Module.split() |> Elixir.List.last()
    "\u{25C6} #{short}"
  end

  defp format_resource(name) do
    short = name |> Module.split() |> Elixir.List.last()
    "  \u{2514} #{short}"
  end
end
