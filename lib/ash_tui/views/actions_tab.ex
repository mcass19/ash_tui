defmodule AshTui.Views.ActionsTab do
  @moduledoc """
  Actions tab view: table showing resource actions.

  Pure function — takes state and rect, returns `[{widget, rect}]`.
  """

  alias AshTui.State
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, Table}

  @doc """
  Renders the actions table for the current resource.
  """
  @spec render(State.t(), Rect.t()) :: [{struct(), Rect.t()}]
  def render(%{current_resource: nil}, rect) do
    [{empty_table("No resource selected"), rect}]
  end

  def render(state, rect) do
    rows =
      Enum.map(state.current_resource.actions, fn action ->
        [
          Atom.to_string(action.name),
          Atom.to_string(action.type),
          if(action.primary?, do: "yes", else: ""),
          format_arguments(action.arguments)
        ]
      end)

    selected =
      if state.focus == :detail and length(rows) > 0 do
        state.detail_selected
      else
        nil
      end

    table = %Table{
      rows: rows,
      header: ["Name", "Type", "Primary?", "Arguments"],
      widths: [{:min, 12}, {:length, 10}, {:length, 9}, {:min, 10}],
      highlight_style: %Style{fg: {:rgb, 255, 215, 0}, modifiers: [:bold]},
      selected: selected,
      column_spacing: 2,
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: {:rgb, 60, 60, 80}}
      }
    }

    [{table, rect}]
  end

  defp format_arguments([]), do: ""

  defp format_arguments(args) do
    args
    |> Enum.map(&Atom.to_string(&1.name))
    |> Enum.join(", ")
  end

  defp empty_table(message) do
    %Table{
      rows: [[message, "", "", ""]],
      header: ["Name", "Type", "Primary?", "Arguments"],
      widths: [{:min, 12}, {:length, 10}, {:length, 9}, {:min, 10}],
      column_spacing: 2,
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: {:rgb, 60, 60, 80}}
      }
    }
  end
end
