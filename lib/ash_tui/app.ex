defmodule AshTui.App do
  @moduledoc """
  Main TUI application using `ExRatatui.App` behaviour.

  Renders the two-panel layout and delegates key handling to `AshTui.State`.
  """

  use ExRatatui.App

  alias AshTui.State
  alias AshTui.Theme
  alias AshTui.Views.{ActionsTab, AttributeDetail, AttributesTab, NavPanel, RelationshipsTab}
  alias ExRatatui.Layout
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, Paragraph, Tabs}

  # ── Callbacks ──────────────────────────────────────────────

  @impl true
  def mount(opts) do
    state = Keyword.fetch!(opts, :state)
    search_input = ExRatatui.text_input_new()
    {:ok, %{state | search_input: search_input}}
  end

  @impl true
  def render(state, frame) do
    area = %Rect{x: 0, y: 0, width: frame.width, height: frame.height}

    if state.show_help do
      render_help(area)
    else
      render_explorer(state, area)
    end
  end

  @impl true
  def handle_event(
        %ExRatatui.Event.Key{code: "q", kind: "press"},
        %{show_help: false, detail_overlay: nil, searching: false} = state
      ) do
    {:stop, state}
  end

  def handle_event(%ExRatatui.Event.Key{code: code, kind: "press"}, state) do
    {:noreply, State.handle_key(state, code)}
  end

  def handle_event(_event, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, _state), do: :ok

  # ── Layout ─────────────────────────────────────────────────

  defp render_explorer(state, area) do
    [header_area, body_area, footer_area] =
      Layout.split(area, :vertical, [
        {:length, 3},
        {:min, 0},
        {:length, 3}
      ])

    [nav_area, detail_area] =
      Layout.split(body_area, :horizontal, [
        {:percentage, 25},
        {:percentage, 75}
      ])

    header_widgets = render_header(state, header_area)
    nav_widgets = NavPanel.render(state, nav_area)
    detail_widgets = render_detail(state, detail_area)
    footer_widgets = render_footer(state, footer_area)

    overlay_widgets =
      if state.detail_overlay do
        AttributeDetail.render(state.detail_overlay, area)
      else
        []
      end

    header_widgets ++ nav_widgets ++ detail_widgets ++ footer_widgets ++ overlay_widgets
  end

  defp render_header(state, rect) do
    breadcrumb = State.breadcrumb(state)

    title =
      if breadcrumb == "" do
        "  \u{1F525} Ash TUI Explorer"
      else
        "  \u{1F525} Ash TUI Explorer  \u{2502}  #{breadcrumb}"
      end

    header = %Paragraph{
      text: title,
      style: %Style{fg: :white, modifiers: [:bold]},
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: Theme.ash_orange()}
      }
    }

    [{header, rect}]
  end

  defp render_detail(state, rect) do
    [tabs_area, content_area] =
      Layout.split(rect, :vertical, [
        {:length, 3},
        {:min, 0}
      ])

    tab_widgets = render_tabs(state, tabs_area)
    content_widgets = render_tab_content(state, content_area)

    tab_widgets ++ content_widgets
  end

  defp render_tabs(state, rect) do
    tab_titles = ["Attributes", "Actions", "Relationships"]

    tab_index =
      Enum.find_index([:attributes, :actions, :relationships], &(&1 == state.current_tab))

    detail_border = Theme.border_style(state.focus == :detail)

    resource_title =
      if state.current_resource do
        name = state.current_resource.name |> Module.split() |> Enum.join(".")
        " #{name} "
      else
        " No resource selected "
      end

    tab_bar = %Tabs{
      titles: tab_titles,
      selected: tab_index,
      style: %Style{fg: :white},
      highlight_style: %Style{fg: Theme.gold(), modifiers: [:bold]},
      block: %Block{
        title: resource_title,
        borders: [:all],
        border_type: :rounded,
        border_style: detail_border
      }
    }

    [{tab_bar, rect}]
  end

  defp render_tab_content(state, rect) do
    case state.current_tab do
      :attributes -> AttributesTab.render(state, rect)
      :actions -> ActionsTab.render(state, rect)
      :relationships -> RelationshipsTab.render(state, rect)
    end
  end

  defp render_footer(state, rect) do
    text =
      cond do
        state.searching ->
          " type to filter  \u{23CE} confirm  Esc cancel"

        state.focus == :nav ->
          " j/k/\u{2191}\u{2193} navigate  \u{23CE} select  h/l/\u{2190}\u{2192} panels  \u{21E5} tabs  / search  ? help  q quit"

        state.focus == :detail ->
          " j/k/\u{2191}\u{2193} navigate  \u{23CE} select  h/l/\u{2190}\u{2192} panels  \u{21E5} tabs  Esc back  ? help  q quit"
      end

    footer = %Paragraph{
      text: text,
      style: %Style{fg: Theme.dim_text()},
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: Theme.unfocused_border_style()
      }
    }

    [{footer, rect}]
  end

  # ── Help Overlay ───────────────────────────────────────────

  defp render_help(area) do
    help_text = """
    \u{1F525} Ash TUI Explorer - Keyboard Reference

    \u{2500}\u{2500}\u{2500} Navigation \u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}
      j / \u{2193}         Move selection down
      k / \u{2191}         Move selection up
      h / \u{2190}         Focus navigation panel
      l / \u{2192}         Focus detail panel
      \u{23CE} Enter      Select / drill into item
      Esc           Go back (pop nav stack)

    \u{2500}\u{2500}\u{2500} Tabs \u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}
      \u{21E5} Tab        Cycle through tabs
      1             Attributes tab
      2             Actions tab
      3             Relationships tab

    \u{2500}\u{2500}\u{2500} Relationships \u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}
      \u{23CE} Enter      Navigate to destination resource
      Esc           Return to previous resource

    \u{2500}\u{2500}\u{2500} Search \u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}
      /             Start filtering resources
      \u{23CE} Enter      Accept filter
      Esc           Clear filter and cancel

    \u{2500}\u{2500}\u{2500} Other \u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}
      ?             Toggle this help
      q             Quit

    Press any key to close this help.
    """

    help = %Paragraph{
      text: help_text,
      style: %Style{fg: :white},
      block: %Block{
        title: " Help ",
        borders: [:all],
        border_type: :double,
        border_style: %Style{fg: Theme.ash_orange()}
      }
    }

    [{help, area}]
  end
end
