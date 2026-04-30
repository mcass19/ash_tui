defmodule AshTui.App do
  @moduledoc """
  Main TUI application using `ExRatatui.App` behaviour.

  Renders the two-panel layout and delegates key handling to `AshTui.State`.

  ## Transports

  This module works across all three ExRatatui transports without changes:

    * **Local** — `AshTui.App.start_link(state: state)` renders to the
      local terminal.
    * **SSH** — `AshTui.App.start_link(transport: :ssh, app_opts: [state: state], ...)`
      serves each SSH client an isolated explorer session.
    * **Distributed** — `AshTui.App.start_link(transport: :distributed, app_opts: [state: state])`
      starts a listener; remote nodes attach via
      `ExRatatui.Distributed.attach(node, AshTui.App)`.

  In practice, use `AshTui.explore/2` or `mix ash.tui` which handle the
  wiring for you.
  """

  use ExRatatui.App

  alias AshTui.State
  alias AshTui.Theme
  alias AshTui.Views.{ActionsTab, AttributeDetail, AttributesTab, NavPanel, RelationshipsTab}
  alias ExRatatui.Layout
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Style
  alias ExRatatui.Text.{Line, Span}
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
    header = %Paragraph{
      text: Theme.brand_title(State.breadcrumb(state)),
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
    tab_index =
      Enum.find_index([:attributes, :actions, :relationships], &(&1 == state.current_tab))

    name =
      case state.current_resource do
        nil -> ""
        resource -> resource.name |> Module.split() |> Enum.join(".")
      end

    tab_bar = %Tabs{
      titles: tab_titles(),
      selected: tab_index,
      style: %Style{fg: :white},
      highlight_style: %Style{fg: Theme.gold(), modifiers: [:bold]},
      block: %Block{
        title: Theme.resource_title(name),
        borders: [:all],
        border_type: :rounded,
        border_style: Theme.border_style(state.focus == :detail)
      }
    }

    [{tab_bar, rect}]
  end

  defp tab_titles do
    [
      %Span{content: "Attributes", style: %Style{fg: :white}},
      %Span{content: "Actions", style: %Style{fg: :white}},
      %Span{content: "Relationships", style: %Style{fg: :white}}
    ]
  end

  defp render_tab_content(state, rect) do
    case state.current_tab do
      :attributes -> AttributesTab.render(state, rect)
      :actions -> ActionsTab.render(state, rect)
      :relationships -> RelationshipsTab.render(state, rect)
    end
  end

  defp render_footer(state, rect) do
    footer = %Paragraph{
      text: footer_line(state),
      block: %Block{
        borders: [:all],
        border_type: :rounded,
        border_style: Theme.unfocused_border_style()
      }
    }

    [{footer, rect}]
  end

  defp footer_line(%{searching: true}) do
    Theme.footer_line([
      {"a-z", "type to filter"},
      {"⏎", "confirm"},
      {"Esc", "cancel", :quit}
    ])
  end

  defp footer_line(_state) do
    Theme.footer_line([
      {"j/k", "navigate"},
      {"⏎", "select"},
      {"h/l", "panels"},
      {"Tab", "tabs"},
      {"/", "search"},
      {"Esc", "back"},
      {"?", "help"},
      {"q", "quit", :quit}
    ])
  end

  # ── Help Overlay ───────────────────────────────────────────

  defp render_help(area) do
    help = %Paragraph{
      text: help_lines(),
      block: %Block{
        title: help_title(),
        borders: [:all],
        border_type: :double,
        border_style: %Style{fg: Theme.ash_orange()},
        style: %Style{bg: Theme.overlay_bg()}
      }
    }

    [{help, area}]
  end

  defp help_title do
    %Line{
      spans: [
        %Span{content: " 🔥 ", style: %Style{}},
        %Span{content: "Keyboard Reference ", style: %Style{fg: :white, modifiers: [:bold]}}
      ]
    }
  end

  defp help_lines do
    [
      blank_line(),
      help_section("Navigation"),
      help_row("j / ↓", "Move selection down"),
      help_row("k / ↑", "Move selection up"),
      help_row("h / ←", "Focus navigation panel"),
      help_row("l / →", "Focus detail panel"),
      help_row("⏎", "Select / drill into item"),
      help_row("Esc", "Go back (pop nav stack)"),
      blank_line(),
      help_section("Tabs"),
      help_row("Tab", "Cycle through tabs"),
      help_row("1", "Attributes tab"),
      help_row("2", "Actions tab"),
      help_row("3", "Relationships tab"),
      blank_line(),
      help_section("Relationships"),
      help_row("⏎", "Navigate to destination resource"),
      help_row("Esc", "Return to previous resource"),
      blank_line(),
      help_section("Search"),
      help_row("/", "Start filtering resources"),
      help_row("⏎", "Accept filter"),
      help_row("Esc", "Clear filter and cancel"),
      blank_line(),
      help_section("Other"),
      help_row("?", "Toggle this help"),
      help_row("q", "Quit", :quit),
      blank_line(),
      %Line{
        spans: [
          %Span{
            content: "  Press any key to close this help.",
            style: %Style{fg: Theme.dim_text()}
          }
        ]
      }
    ]
  end

  defp help_section(label) do
    %Line{
      spans: [
        %Span{content: "  ── ", style: %Style{fg: Theme.dim_text()}},
        %Span{content: label, style: %Style{fg: Theme.cornflower(), modifiers: [:bold]}},
        %Span{content: " ──", style: %Style{fg: Theme.dim_text()}}
      ]
    }
  end

  defp help_row(keys, description, kind \\ :default) do
    %Line{
      spans: [
        %Span{content: "  ", style: %Style{}},
        Theme.key_pill(keys, kind),
        %Span{content: "  ", style: %Style{}},
        %Span{content: description, style: %Style{fg: :white}}
      ]
    }
  end

  defp blank_line, do: %Line{spans: [%Span{content: "", style: %Style{}}]}
end
