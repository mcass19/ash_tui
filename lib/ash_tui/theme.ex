defmodule AshTui.Theme do
  @moduledoc """
  Color and style constants for the TUI.
  """

  alias ExRatatui.Style

  # ── Colors ──────────────────────────────────────────────────

  def ash_orange, do: {:rgb, 255, 107, 53}
  def cornflower, do: {:rgb, 100, 149, 237}
  def gold, do: {:rgb, 255, 215, 0}
  def highlight_bg, do: {:rgb, 40, 40, 60}
  def dim_border, do: {:rgb, 60, 60, 80}
  def dim_text, do: {:rgb, 150, 150, 170}
  def overlay_bg, do: {:rgb, 20, 20, 30}

  # ── Composite Styles ───────────────────────────────────────

  def highlight_style do
    %Style{
      fg: gold(),
      bg: highlight_bg(),
      modifiers: [:bold]
    }
  end

  def focused_border_style do
    %Style{fg: cornflower()}
  end

  def unfocused_border_style do
    %Style{fg: dim_border()}
  end

  def border_style(focused?) do
    if focused?, do: focused_border_style(), else: unfocused_border_style()
  end
end
