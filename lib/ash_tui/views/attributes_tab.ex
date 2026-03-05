defmodule AshTui.Views.AttributesTab do
  @moduledoc """
  Attributes tab view: table showing resource attributes.

  Pure function — takes state and rect, returns `[{widget, rect}]`.
  """

  alias AshTui.Format
  alias AshTui.State
  alias AshTui.Theme
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Widgets.{Block, Table}

  @header ["Name", "Type", "Required?"]
  @widths [{:min, 12}, {:min, 12}, {:length, 10}]

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
          Format.format_type(attr.type),
          format_required(attr)
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

  defp format_required(%{primary_key?: true, generated?: true}), do: "\u{1F511} auto"
  defp format_required(%{primary_key?: true}), do: "\u{1F511}"
  defp format_required(%{generated?: true}), do: "\u{2699} auto"
  defp format_required(%{allow_nil?: false}), do: "\u{2713} yes"
  defp format_required(_), do: "\u{25CB}"

  defp empty_table(message) do
    %Table{
      rows: [[message, "", ""]],
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
