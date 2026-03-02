defmodule AshTui.Views.AttributesTab do
  @moduledoc """
  Attributes tab view: table showing resource attributes.

  Pure function — takes state and rect, returns `[{widget, rect}]`.
  """

  alias AshTui.State
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, Table}

  @doc """
  Renders the attributes table for the current resource.
  """
  @spec render(State.t(), Rect.t()) :: [{struct(), Rect.t()}]
  def render(%{current_resource: nil}, rect) do
    [{empty_table("No resource selected"), rect}]
  end

  def render(state, rect) do
    rows =
      Enum.map(state.current_resource.attributes, fn attr ->
        [
          Atom.to_string(attr.name),
          format_type(attr.type),
          format_required(attr),
          format_constraints(attr.constraints)
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
      header: ["Name", "Type", "Required?", "Constraints"],
      widths: [{:min, 12}, {:min, 12}, {:length, 10}, {:min, 10}],
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

  defp format_type(type) when is_atom(type), do: Atom.to_string(type)
  defp format_type({:array, inner}), do: "[#{format_type(inner)}]"
  defp format_type(type), do: inspect(type)

  defp format_required(%{primary_key?: true, generated?: true}), do: "auto"
  defp format_required(%{primary_key?: true}), do: "pk"
  defp format_required(%{generated?: true}), do: "auto"
  defp format_required(%{allow_nil?: false}), do: "yes"
  defp format_required(_), do: "no"

  defp format_constraints([]), do: ""
  defp format_constraints(constraints), do: inspect(constraints)

  defp empty_table(message) do
    %Table{
      rows: [[message, "", "", ""]],
      header: ["Name", "Type", "Required?", "Constraints"],
      widths: [{:min, 12}, {:min, 12}, {:length, 10}, {:min, 10}],
      column_spacing: 2,
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: {:rgb, 60, 60, 80}}
      }
    }
  end
end
