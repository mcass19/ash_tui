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
      header: ["Name", "Type", "Required?"],
      widths: [{:min, 12}, {:min, 12}, {:length, 10}],
      highlight_style: %Style{
        fg: {:rgb, 255, 215, 0},
        bg: {:rgb, 40, 40, 60},
        modifiers: [:bold]
      },
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

  defp format_type(type) when is_atom(type) do
    type
    |> Atom.to_string()
    |> strip_type_prefix()
  end

  defp format_type({:array, inner}), do: "[#{format_type(inner)}]"

  defp format_type(type) do
    type
    |> inspect()
    |> strip_type_prefix()
  end

  defp strip_type_prefix("Elixir.Ash.Type." <> rest), do: rest
  defp strip_type_prefix("Elixir." <> rest), do: rest
  defp strip_type_prefix(other), do: other

  defp format_required(%{primary_key?: true, generated?: true}), do: "\u{1F511} auto"
  defp format_required(%{primary_key?: true}), do: "\u{1F511}"
  defp format_required(%{generated?: true}), do: "\u{2699} auto"
  defp format_required(%{allow_nil?: false}), do: "\u{2713} yes"
  defp format_required(_), do: "\u{25CB}"

  defp empty_table(message) do
    %Table{
      rows: [[message, "", ""]],
      header: ["Name", "Type", "Required?"],
      widths: [{:min, 12}, {:min, 12}, {:length, 10}],
      column_spacing: 2,
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: {:rgb, 60, 60, 80}}
      }
    }
  end
end
