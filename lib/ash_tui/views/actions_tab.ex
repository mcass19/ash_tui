defmodule AshTui.Views.ActionsTab do
  @moduledoc """
  Actions tab view: table showing resource actions.

  Pure function — takes state and rect, returns `[{widget, rect}]`.
  """

  alias AshTui.State
  alias AshTui.Theme
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Widgets.{Block, Scrollbar, Table}

  @header ["Name", "Type", "Primary?", "Arguments"]
  @widths [{:min, 12}, {:length, 14}, {:length, 9}, {:min, 10}]

  @doc """
  Renders the actions table for the current resource.

  Returns a list of `{widget, rect}` tuples containing the actions table
  (and optionally a scrollbar when content overflows).

  ## Examples

      iex> domains = AshTui.Introspection.from_data([
      ...>   %{
      ...>     name: MyApp.Accounts,
      ...>     resources: [
      ...>       %{
      ...>         name: MyApp.Accounts.User,
      ...>         attributes: [%{name: :id, type: :uuid, primary_key?: true}],
      ...>         actions: [%{name: :read, type: :read, primary?: true}],
      ...>         relationships: []
      ...>       }
      ...>     ]
      ...>   }
      ...> ])
      iex> state = AshTui.State.new(domains) |> Map.put(:current_tab, :actions)
      iex> rect = %ExRatatui.Layout.Rect{x: 0, y: 0, width: 60, height: 20}
      iex> [{%ExRatatui.Widgets.Table{}, ^rect}] =
      ...>   AshTui.Views.ActionsTab.render(state, rect)
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
          format_type(action.type),
          if(action.primary?, do: "\u{2605}", else: ""),
          format_arguments(action.arguments)
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

  defp format_type(:create), do: "\u{FF0B} create"
  defp format_type(:read), do: "\u{1F441} read"
  defp format_type(:update), do: "\u{270F} update"
  defp format_type(:destroy), do: "\u{2715} destroy"
  defp format_type(type), do: Atom.to_string(type)

  defp format_arguments([]), do: ""

  defp format_arguments(args) do
    Enum.map_join(args, ", ", &Atom.to_string(&1.name))
  end

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
