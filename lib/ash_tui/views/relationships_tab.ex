defmodule AshTui.Views.RelationshipsTab do
  @moduledoc """
  Relationships tab view: table showing resource relationships.

  Relationships are navigable — pressing Enter on a relationship
  jumps to the destination resource.

  Pure function — takes state and rect, returns `[{widget, rect}]`.
  """

  alias AshTui.Format
  alias AshTui.State
  alias AshTui.Theme
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Widgets.{Block, Table}

  @header ["Name", "Type", "Destination", ""]
  @widths [{:min, 12}, {:length, 18}, {:min, 15}, {:length, 12}]

  @doc """
  Renders the relationships table for the current resource.
  """
  @spec render(State.t(), Rect.t()) :: [{struct(), Rect.t()}]
  def render(%{current_resource: nil}, rect) do
    [{empty_table("No resource selected"), rect}]
  end

  def render(state, rect) do
    rows =
      Enum.map(state.current_resource.relationships, fn rel ->
        [
          Atom.to_string(rel.name),
          format_type(rel.type),
          Format.short_name(rel.destination),
          "\u{23CE} drill in"
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
      header: @header,
      widths: @widths,
      highlight_style: Theme.highlight_style(),
      selected: selected,
      column_spacing: 2,
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: Theme.unfocused_border_style()
      }
    }

    [{table, rect}]
  end

  defp format_type(:belongs_to), do: "\u{2190} belongs_to"
  defp format_type(:has_one), do: "\u{2192} has_one"
  defp format_type(:has_many), do: "\u{2192}* has_many"
  defp format_type(:many_to_many), do: "\u{2194} many_to_many"
  defp format_type(type), do: Atom.to_string(type)

  defp empty_table(message) do
    %Table{
      rows: [[message, "", "", ""]],
      header: @header,
      widths: @widths,
      column_spacing: 2,
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: Theme.unfocused_border_style()
      }
    }
  end
end
