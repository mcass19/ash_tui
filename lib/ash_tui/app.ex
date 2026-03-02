defmodule AshTui.App do
  @moduledoc """
  Main TUI application using `ExRatatui.App` behaviour.

  Renders the two-panel layout and delegates key handling to `AshTui.State`.
  """

  use ExRatatui.App

  alias AshTui.State
  alias AshTui.Views.{ActionsTab, AttributesTab, NavPanel, RelationshipsTab}
  alias ExRatatui.Layout
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Widgets.{Block, Paragraph}

  # ── Callbacks ──────────────────────────────────────────────

  @impl true
  def mount(opts) do
    state = Keyword.fetch!(opts, :state)
    {:ok, state}
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
  def handle_event(%ExRatatui.Event.Key{code: "q", kind: "press"}, %{show_help: false} = state) do
    {:stop, state}
  end

  def handle_event(%ExRatatui.Event.Key{code: code, kind: "press"}, state) do
    {:noreply, State.handle_key(state, code)}
  end

  def handle_event(_event, state) do
    {:noreply, state}
  end

  @impl true
  def terminate(:normal, _state), do: System.stop(0)
  def terminate(_reason, _state), do: :ok

  # ── Layout ─────────────────────────────────────────────────

  defp render_explorer(state, area) do
    [header_area, body_area, footer_area] =
      Layout.split(area, :vertical, [
        {:length, 3},
        {:min, 0},
        {:length, 1}
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

    header_widgets ++ nav_widgets ++ detail_widgets ++ footer_widgets
  end

  defp render_header(state, rect) do
    breadcrumb = State.breadcrumb(state)

    title =
      if breadcrumb == "" do
        "  Ash TUI Explorer"
      else
        "  Ash TUI Explorer  |  #{breadcrumb}"
      end

    header = %Paragraph{
      text: title,
      style: %Style{fg: :white, modifiers: [:bold]},
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: %Style{fg: {:rgb, 100, 149, 237}}
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
    labels = ["1:Attributes", "2:Actions", "3:Relationships"]
    tabs = [:attributes, :actions, :relationships]

    text =
      labels
      |> Enum.zip(tabs)
      |> Enum.map_join("  ", fn {label, tab} ->
        if tab == state.current_tab do
          "[#{label}]"
        else
          " #{label} "
        end
      end)

    detail_border =
      if state.focus == :detail do
        %Style{fg: {:rgb, 100, 149, 237}}
      else
        %Style{fg: {:rgb, 60, 60, 80}}
      end

    resource_title =
      if state.current_resource do
        name = state.current_resource.name |> Module.split() |> Enum.join(".")
        " #{name} "
      else
        " No resource selected "
      end

    tab_bar = %Paragraph{
      text: "  #{text}",
      style: %Style{fg: :white},
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
      case state.focus do
        :nav ->
          " j/k:navigate  Enter:select  l/->:detail  Tab:switch tab  ?:help  q:quit"

        :detail ->
          " j/k:navigate  Enter:drill in  h/<-:nav  Tab:switch tab  Esc:back  ?:help  q:quit"
      end

    footer = %Paragraph{
      text: text,
      style: %Style{fg: {:rgb, 100, 100, 120}}
    }

    [{footer, rect}]
  end

  # ── Help Overlay ───────────────────────────────────────────

  defp render_help(area) do
    help_text = """
    Ash TUI Explorer - Keyboard Reference

    Navigation
      j / Down      Move selection down
      k / Up        Move selection up
      h / Left      Focus navigation panel
      l / Right     Focus detail panel
      Enter         Select / drill into item
      Esc           Go back (pop nav stack)

    Tabs
      Tab           Cycle through tabs
      1             Attributes tab
      2             Actions tab
      3             Relationships tab

    Relationships
      Enter         Navigate to destination resource
      Esc           Return to previous resource

    Other
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
        border_style: %Style{fg: {:rgb, 100, 149, 237}}
      }
    }

    [{help, area}]
  end
end
