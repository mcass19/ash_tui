defmodule AshTui.Views.RelationshipsTab do
  @moduledoc """
  Relationships tab view: table showing resource relationships.

  Relationships are navigable — pressing Enter on a relationship
  jumps to the destination resource.

  Pure function — takes state and rect, returns `[{widget, rect}]`.
  """

  alias AshTui.State
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, Table}

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
          short_name(rel.destination),
          "Enter ->"
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
      header: ["Name", "Type", "Destination", ""],
      widths: [{:min, 12}, {:length, 14}, {:min, 15}, {:length, 10}],
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

  defp format_type(:belongs_to), do: "belongs_to"
  defp format_type(:has_one), do: "has_one"
  defp format_type(:has_many), do: "has_many"
  defp format_type(:many_to_many), do: "many_to_many"
  defp format_type(type), do: Atom.to_string(type)

  defp short_name(module) when is_atom(module) do
    module |> Module.split() |> Elixir.List.last()
  end

  defp empty_table(message) do
    %Table{
      rows: [[message, "", "", ""]],
      header: ["Name", "Type", "Destination", ""],
      widths: [{:min, 12}, {:length, 14}, {:min, 15}, {:length, 10}],
      column_spacing: 2,
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: {:rgb, 60, 60, 80}}
      }
    }
  end
end
