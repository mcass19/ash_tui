defmodule AshTui.Theme do
  @moduledoc """
  Color and style constants for the TUI.

  Provides a consistent visual palette based on the Ash Framework brand
  colors. All functions are pure and return either a color tuple or an
  `%ExRatatui.Style{}` struct.

  ## Colors

    * `ash_orange/0` - Ash brand orange
    * `cornflower/0` - accent blue for focused borders
    * `gold/0` - highlight and selection color
    * `highlight_bg/0` - subtle background for selected rows
    * `dim_border/0` - muted border color for unfocused panels
    * `dim_text/0` - muted text for secondary information
    * `overlay_bg/0` - dark background for modal overlays

  ## Composite Styles

    * `highlight_style/0` - bold gold text on dark background (selected items)
    * `focused_border_style/0` - cornflower border (active panel)
    * `unfocused_border_style/0` - dim border (inactive panel)
    * `border_style/1` - convenience toggle between focused/unfocused
  """

  alias ExRatatui.Style

  # ── Colors ──────────────────────────────────────────────────

  @doc """
  Ash Framework brand orange.

  ## Examples

      iex> AshTui.Theme.ash_orange()
      {:rgb, 255, 107, 53}
  """
  @spec ash_orange() :: ExRatatui.Style.color()
  def ash_orange, do: {:rgb, 255, 107, 53}

  @doc """
  Cornflower blue, used for focused panel borders.

  ## Examples

      iex> AshTui.Theme.cornflower()
      {:rgb, 100, 149, 237}
  """
  @spec cornflower() :: ExRatatui.Style.color()
  def cornflower, do: {:rgb, 100, 149, 237}

  @doc """
  Gold, used for highlights and selected items.

  ## Examples

      iex> AshTui.Theme.gold()
      {:rgb, 255, 215, 0}
  """
  @spec gold() :: ExRatatui.Style.color()
  def gold, do: {:rgb, 255, 215, 0}

  @doc """
  Subtle dark background for selected rows.

  ## Examples

      iex> AshTui.Theme.highlight_bg()
      {:rgb, 40, 40, 60}
  """
  @spec highlight_bg() :: ExRatatui.Style.color()
  def highlight_bg, do: {:rgb, 40, 40, 60}

  @doc """
  Muted border color for unfocused panels.

  ## Examples

      iex> AshTui.Theme.dim_border()
      {:rgb, 60, 60, 80}
  """
  @spec dim_border() :: ExRatatui.Style.color()
  def dim_border, do: {:rgb, 60, 60, 80}

  @doc """
  Muted text color for secondary information.

  ## Examples

      iex> AshTui.Theme.dim_text()
      {:rgb, 150, 150, 170}
  """
  @spec dim_text() :: ExRatatui.Style.color()
  def dim_text, do: {:rgb, 150, 150, 170}

  @doc """
  Dark background for modal overlays.

  ## Examples

      iex> AshTui.Theme.overlay_bg()
      {:rgb, 20, 20, 30}
  """
  @spec overlay_bg() :: ExRatatui.Style.color()
  def overlay_bg, do: {:rgb, 20, 20, 30}

  # ── Composite Styles ───────────────────────────────────────

  @doc """
  Bold gold text on a dark background, used for selected items.

  ## Examples

      iex> style = AshTui.Theme.highlight_style()
      iex> style.fg
      {:rgb, 255, 215, 0}
      iex> style.modifiers
      [:bold]
  """
  @spec highlight_style() :: Style.t()
  def highlight_style do
    %Style{
      fg: gold(),
      bg: highlight_bg(),
      modifiers: [:bold]
    }
  end

  @doc """
  Cornflower blue border style for the active/focused panel.

  ## Examples

      iex> style = AshTui.Theme.focused_border_style()
      iex> style.fg
      {:rgb, 100, 149, 237}
  """
  @spec focused_border_style() :: Style.t()
  def focused_border_style do
    %Style{fg: cornflower()}
  end

  @doc """
  Dim border style for inactive/unfocused panels.

  ## Examples

      iex> style = AshTui.Theme.unfocused_border_style()
      iex> style.fg
      {:rgb, 60, 60, 80}
  """
  @spec unfocused_border_style() :: Style.t()
  def unfocused_border_style do
    %Style{fg: dim_border()}
  end

  @doc """
  Returns `focused_border_style/0` when `focused?` is `true`,
  `unfocused_border_style/0` otherwise.

  ## Examples

      iex> AshTui.Theme.border_style(true) == AshTui.Theme.focused_border_style()
      true

      iex> AshTui.Theme.border_style(false) == AshTui.Theme.unfocused_border_style()
      true
  """
  @spec border_style(boolean()) :: Style.t()
  def border_style(focused?) do
    if focused?, do: focused_border_style(), else: unfocused_border_style()
  end
end
