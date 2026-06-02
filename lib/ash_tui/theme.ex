defmodule AshTui.Theme do
  @moduledoc """
  Color, style, and rich-text constants for the TUI.

  Provides a consistent visual palette based on the Ash Framework brand
  colors. All functions are pure and return a color tuple, an
  `%ExRatatui.Style{}`, an `%ExRatatui.Text.Span{}`, or an
  `%ExRatatui.Text.Line{}` — never a side effect.

  The palette is held internally as a single `%ExRatatui.Theme{}` struct;
  the color accessors below read individual slots from it, and the border
  styles delegate to `ExRatatui.Theme.border_style/2`.

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

  ## Rich Text

    * `brand_title/1` - branded header line ("🔥 Ash TUI Explorer · breadcrumb")
    * `resource_title/1` - dim-domain + bold-resource line for the tabs block
    * `key_pill/2` - colored "key" pill `%Span{}` for footer / help hints
    * `dim_span/1` - dim-text descriptor span between pills
    * `footer_line/1` - assembles a `%Line{}` from a list of `{keys, label}` pairs
  """

  alias ExRatatui.Style
  alias ExRatatui.Text.{Line, Span}

  # ── Colors ──────────────────────────────────────────────────

  @doc """
  Ash Framework brand orange.

  ## Examples

      iex> AshTui.Theme.ash_orange()
      {:rgb, 255, 107, 53}
  """
  @spec ash_orange() :: ExRatatui.Style.color()
  def ash_orange, do: palette().primary

  @doc """
  Cornflower blue, used for focused panel borders.

  ## Examples

      iex> AshTui.Theme.cornflower()
      {:rgb, 100, 149, 237}
  """
  @spec cornflower() :: ExRatatui.Style.color()
  def cornflower, do: palette().border_focused

  @doc """
  Gold, used for highlights and selected items.

  ## Examples

      iex> AshTui.Theme.gold()
      {:rgb, 255, 215, 0}
  """
  @spec gold() :: ExRatatui.Style.color()
  def gold, do: palette().accent

  @doc """
  Subtle dark background for selected rows.

  ## Examples

      iex> AshTui.Theme.highlight_bg()
      {:rgb, 40, 40, 60}
  """
  @spec highlight_bg() :: ExRatatui.Style.color()
  def highlight_bg, do: palette().surface_alt

  @doc """
  Muted border color for unfocused panels.

  ## Examples

      iex> AshTui.Theme.dim_border()
      {:rgb, 60, 60, 80}
  """
  @spec dim_border() :: ExRatatui.Style.color()
  def dim_border, do: palette().border

  @doc """
  Muted text color for secondary information.

  ## Examples

      iex> AshTui.Theme.dim_text()
      {:rgb, 150, 150, 170}
  """
  @spec dim_text() :: ExRatatui.Style.color()
  def dim_text, do: palette().text_dim

  @doc """
  Dark background for modal overlays.

  ## Examples

      iex> AshTui.Theme.overlay_bg()
      {:rgb, 20, 20, 30}
  """
  @spec overlay_bg() :: ExRatatui.Style.color()
  def overlay_bg, do: palette().surface

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
    ExRatatui.Theme.border_style(palette(), focused: true)
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
    ExRatatui.Theme.border_style(palette())
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

  # ── Rich Text ──────────────────────────────────────────────

  @doc ~S"""
  Branded header line — `🔥 Ash TUI Explorer` with an optional breadcrumb.

  `Ash` renders in `ash_orange/0` bold, `TUI` in `gold/0` bold, `Explorer`
  in white, and the breadcrumb in `cornflower/0` bold separated by a dim
  `│`.

  ## Examples

      iex> %ExRatatui.Text.Line{spans: spans} = AshTui.Theme.brand_title("")
      iex> Enum.map(spans, & &1.content)
      [" 🔥 ", "Ash", " ", "TUI", " ", "Explorer "]

      iex> %ExRatatui.Text.Line{spans: spans} = AshTui.Theme.brand_title("User")
      iex> Enum.map_join(spans, "", & &1.content)
      " 🔥 Ash TUI Explorer  │  User "
  """
  @spec brand_title(String.t()) :: Line.t()
  def brand_title(breadcrumb) when is_binary(breadcrumb) do
    base = [
      %Span{content: " 🔥 ", style: %Style{}},
      %Span{content: "Ash", style: %Style{fg: ash_orange(), modifiers: [:bold]}},
      %Span{content: " ", style: %Style{}},
      %Span{content: "TUI", style: %Style{fg: gold(), modifiers: [:bold]}},
      %Span{content: " ", style: %Style{}},
      %Span{content: "Explorer ", style: %Style{fg: :white, modifiers: [:bold]}}
    ]

    spans =
      case breadcrumb do
        "" ->
          base

        crumb ->
          base ++
            [
              %Span{content: " │  ", style: %Style{fg: dim_text()}},
              %Span{content: "#{crumb} ", style: %Style{fg: cornflower(), modifiers: [:bold]}}
            ]
      end

    %Line{spans: spans}
  end

  @doc ~S"""
  Title line for the detail (tabs) block — the domain prefix renders dim
  while the bare resource name is bold gold.

  ## Examples

      iex> %ExRatatui.Text.Line{spans: spans} =
      ...>   AshTui.Theme.resource_title("AshDemo.Accounts.User")
      iex> Enum.map(spans, & &1.content)
      [" ", "AshDemo.Accounts.", "User", " "]

      iex> %ExRatatui.Text.Line{spans: [_, _, name, _]} =
      ...>   AshTui.Theme.resource_title("Bare")
      iex> name.content
      "Bare"

      iex> %ExRatatui.Text.Line{spans: [%{content: only}]} =
      ...>   AshTui.Theme.resource_title("")
      iex> only
      " No resource selected "
  """
  @spec resource_title(String.t()) :: Line.t()
  def resource_title("") do
    %Line{
      spans: [%Span{content: " No resource selected ", style: %Style{fg: dim_text()}}]
    }
  end

  def resource_title(name) when is_binary(name) do
    {prefix, base} =
      case String.split(name, ".") do
        [_only] ->
          {"", name}

        parts ->
          [last | head] = Enum.reverse(parts)
          {Enum.join(Enum.reverse(head), ".") <> ".", last}
      end

    %Line{
      spans: [
        %Span{content: " ", style: %Style{}},
        %Span{content: prefix, style: %Style{fg: dim_text()}},
        %Span{content: base, style: %Style{fg: gold(), modifiers: [:bold]}},
        %Span{content: " ", style: %Style{}}
      ]
    }
  end

  @doc ~S"""
  Colored "key" pill — keys render bold over a colored background, used
  in footer and help hints.

  Pass `:quit` for the warning red pill (used for `q`); any other atom
  uses the calm cyan pill.

  ## Examples

      iex> pill = AshTui.Theme.key_pill("Tab")
      iex> pill.style.bg
      :cyan
      iex> pill.content
      " Tab "

      iex> pill = AshTui.Theme.key_pill("q", :quit)
      iex> pill.style.bg
      :red
      iex> :bold in pill.style.modifiers
      true
  """
  @spec key_pill(String.t(), :default | :quit) :: Span.t()
  def key_pill(label, kind \\ :default) when is_binary(label) do
    style =
      case kind do
        :quit -> %Style{bg: :red, fg: :white, modifiers: [:bold]}
        _ -> %Style{bg: :cyan, fg: :black, modifiers: [:bold]}
      end

    %Span{content: " #{label} ", style: style}
  end

  @doc ~S"""
  Dim span used between key pills in the footer / help.

  ## Examples

      iex> span = AshTui.Theme.dim_span(" navigate")
      iex> span.content
      " navigate"
      iex> span.style.fg == AshTui.Theme.dim_text()
      true
  """
  @spec dim_span(String.t()) :: Span.t()
  def dim_span(text) when is_binary(text) do
    %Span{content: text, style: %Style{fg: dim_text()}}
  end

  @doc ~S"""
  Builds a footer `%Line{}` from a list of `{label, description}` pairs.

  Each entry becomes a key pill followed by a dim description and a
  trailing space. Pass a `{label, description, :quit}` triple to render
  the warning-red pill.

  ## Examples

      iex> %ExRatatui.Text.Line{spans: spans} =
      ...>   AshTui.Theme.footer_line([{"Tab", "cycle"}, {"q", "quit", :quit}])
      iex> Enum.map_join(spans, "", & &1.content)
      " Tab  cycle  q  quit "
  """
  @spec footer_line([{String.t(), String.t()} | {String.t(), String.t(), atom()}]) :: Line.t()
  def footer_line(entries) when is_list(entries) do
    spans =
      entries
      |> Enum.flat_map(fn
        {label, description} ->
          [key_pill(label), dim_span(" #{description} ")]

        {label, description, kind} ->
          [key_pill(label, kind), dim_span(" #{description} ")]
      end)

    %Line{spans: spans}
  end

  # ── Palette ────────────────────────────────────────────────

  # The whole palette lives in one `%ExRatatui.Theme{}` struct; the color
  # accessors above read individual slots from it. AshTui's brand colors
  # map onto the semantic slots below. The two background colors are a
  # slight stretch — the modal background lands on `:surface` and the
  # selected-row background on `:surface_alt` — but keeping every color
  # in one struct is the point of the migration.
  defp palette do
    %ExRatatui.Theme{
      primary: {:rgb, 255, 107, 53},
      accent: {:rgb, 255, 215, 0},
      border: {:rgb, 60, 60, 80},
      border_focused: {:rgb, 100, 149, 237},
      surface: {:rgb, 20, 20, 30},
      surface_alt: {:rgb, 40, 40, 60},
      text: :white,
      text_dim: {:rgb, 150, 150, 170},
      success: :green,
      warning: :yellow,
      danger: :red
    }
  end
end
