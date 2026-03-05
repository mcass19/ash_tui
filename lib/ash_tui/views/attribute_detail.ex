defmodule AshTui.Views.AttributeDetail do
  @moduledoc """
  Overlay view showing full details for a selected attribute.
  """

  alias AshTui.Format
  alias AshTui.Introspection.AttributeInfo
  alias AshTui.Theme
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, Clear, Paragraph}

  @doc """
  Renders a centered overlay with full attribute details.

  Shows name, type, required status, primary key, generated flag, and constraints.
  The overlay is rendered on top of the existing layout and dismissed with Esc.
  """
  @spec render(AttributeInfo.t(), Rect.t()) :: [{struct(), Rect.t()}]
  def render(attr, area) do
    constraint_lines =
      case attr.constraints do
        [] ->
          ["  Constraints:  none"]

        constraints ->
          formatted = Enum.map(constraints, &format_constraint/1)

          [
            "  Constraints:" | Enum.map(formatted, &"    - #{&1}")
          ]
      end

    lines =
      [
        "  Name:         #{attr.name}",
        "  Type:         #{Format.format_type(attr.type)}",
        "  Required:     #{format_required(attr)}",
        "  Primary Key:  #{yes_no(attr.primary_key?)}",
        "  Generated:    #{yes_no(attr.generated?)}"
      ] ++
        constraint_lines ++
        [
          "",
          "  Press Esc to close"
        ]

    text = Enum.join(lines, "\n")

    # Center the overlay
    overlay_w = min(area.width - 4, 60)
    overlay_h = min(length(lines) + 2, area.height - 4)
    overlay_x = area.x + div(area.width - overlay_w, 2)
    overlay_y = area.y + div(area.height - overlay_h, 2)

    overlay_rect = %Rect{x: overlay_x, y: overlay_y, width: overlay_w, height: overlay_h}

    widget = %Paragraph{
      text: text,
      style: %Style{fg: :white},
      block: %Block{
        title: " Attribute: #{attr.name} ",
        borders: [:all],
        border_type: :double,
        border_style: %Style{fg: Theme.gold()},
        style: %Style{bg: Theme.overlay_bg()}
      }
    }

    [{%Clear{}, overlay_rect}, {widget, overlay_rect}]
  end

  defp format_required(%{primary_key?: true}), do: "primary key"
  defp format_required(%{allow_nil?: false}), do: "yes"
  defp format_required(_), do: "no"

  defp yes_no(true), do: "yes"
  defp yes_no(false), do: "no"

  defp format_constraint({:trim?, true}), do: "trim"
  defp format_constraint({:trim?, false}), do: "!trim"
  defp format_constraint({:allow_empty?, true}), do: "allow empty"
  defp format_constraint({:allow_empty?, false}), do: "!empty"

  defp format_constraint({:one_of, values}) do
    vals = Enum.map_join(values, "|", &to_string/1)
    "one_of: #{vals}"
  end

  defp format_constraint({:precision, :microsecond}), do: "precision: microsecond"
  defp format_constraint({:precision, :millisecond}), do: "precision: millisecond"
  defp format_constraint({:precision, :second}), do: "precision: second"

  defp format_constraint({key, value}), do: "#{key}: #{inspect(value)}"
end
