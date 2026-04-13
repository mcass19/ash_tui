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
  alias ExRatatui.Widgets.{Block, Scrollbar, Table}

  @header ["Name", "Type", "Destination", ""]
  @widths [{:min, 12}, {:length, 18}, {:min, 15}, {:length, 12}]

  @doc """
  Renders the relationships table for the current resource.

  Returns a list of `{widget, rect}` tuples containing the relationships table
  (and optionally a scrollbar when content overflows). Relationships are
  navigable — pressing Enter on a row jumps to the destination resource.

  ## Examples

      iex> domains = AshTui.Introspection.from_data([
      ...>   %{
      ...>     name: MyApp.Accounts,
      ...>     resources: [
      ...>       %{
      ...>         name: MyApp.Accounts.User,
      ...>         attributes: [%{name: :id, type: :uuid, primary_key?: true}],
      ...>         actions: [],
      ...>         relationships: [%{name: :posts, type: :has_many, destination: MyApp.Blog.Post}]
      ...>       }
      ...>     ]
      ...>   }
      ...> ])
      iex> state = AshTui.State.new(domains) |> Map.put(:current_tab, :relationships)
      iex> rect = %ExRatatui.Layout.Rect{x: 0, y: 0, width: 60, height: 20}
      iex> [{%ExRatatui.Widgets.Table{}, ^rect}] =
      ...>   AshTui.Views.RelationshipsTab.render(state, rect)
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
      if state.focus == :detail and rows != [] do
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

    viewport_h = max(rect.height - 3, 1)
    row_count = length(rows)

    scrollbar_widgets =
      if row_count > viewport_h and selected != nil do
        [
          {%Scrollbar{
             orientation: :vertical_right,
             content_length: row_count,
             position: selected,
             viewport_content_length: viewport_h,
             thumb_style: Theme.focused_border_style(),
             track_style: Theme.unfocused_border_style()
           }, rect}
        ]
      else
        []
      end

    [{table, rect}] ++ scrollbar_widgets
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
