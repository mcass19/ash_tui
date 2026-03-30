defmodule AshTui.Views.AttributeDetailTest do
  use ExUnit.Case, async: true

  alias AshTui.Introspection.AttributeInfo
  alias AshTui.Views.AttributeDetail
  alias ExRatatui.Layout.Rect
  alias ExRatatui.Native

  doctest AshTui.Views.AttributeDetail

  setup do
    terminal = ExRatatui.init_test_terminal(80, 24)
    on_exit(fn -> Native.restore_terminal(terminal) end)
    area = %Rect{x: 0, y: 0, width: 80, height: 24}
    %{terminal: terminal, area: area}
  end

  describe "render/2" do
    test "renders attribute name", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{name: :email, type: :string, allow_nil?: false}
      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "email"
      assert content =~ "Attribute: email"
    end

    test "renders type information", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{name: :id, type: :uuid, primary_key?: true, generated?: true}
      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "uuid"
      # Boolean fields shown with checkbox-style indicators
      assert content =~ "Primary Key"
      assert content =~ "Generated"
    end

    test "renders required status", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{name: :title, type: :string, allow_nil?: false}
      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Required:"
      assert content =~ "yes"
    end

    test "renders primary key required status", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{name: :id, type: :uuid, primary_key?: true}
      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "primary key"
    end

    test "renders no constraints when empty", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{name: :id, type: :uuid, constraints: []}
      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Constraints:"
      assert content =~ "none"
    end

    test "renders trim constraint", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{name: :name, type: :string, constraints: [trim?: true]}
      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "trim"
    end

    test "renders allow_empty constraint", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{
        name: :bio,
        type: :string,
        constraints: [allow_empty?: true]
      }

      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "allow empty"
    end

    test "renders one_of constraint", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{
        name: :status,
        type: :atom,
        constraints: [one_of: [:draft, :published]]
      }

      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "one_of: draft|published"
    end

    test "renders precision constraints", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{
        name: :inserted_at,
        type: :utc_datetime_usec,
        constraints: [precision: :microsecond]
      }

      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "precision: microsecond"
    end

    test "renders multiple constraints as separate lines", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{
        name: :email,
        type: :string,
        allow_nil?: false,
        constraints: [trim?: true, allow_empty?: false]
      }

      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "trim"
      assert content =~ "!empty"
    end

    test "renders Esc hint", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{name: :id, type: :uuid}
      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "Esc"
    end

    test "renders array types", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{name: :tags, type: {:array, :string}}
      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "[string]"
    end

    test "renders one_of constraint with string values", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{
        name: :color,
        type: :string,
        constraints: [one_of: ["red", "green", "blue"]]
      }

      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "one_of: red|green|blue"
    end

    test "overlay is centered within area", %{area: area} do
      attr = %AttributeInfo{name: :id, type: :uuid}
      [{_, rect} | _] = AttributeDetail.render(attr, area)

      # Overlay should be smaller than the area
      assert rect.width < area.width
      assert rect.height < area.height

      # And centered
      assert rect.x > 0
      assert rect.y > 0
    end

    test "renders trim false constraint", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{name: :raw, type: :string, constraints: [trim?: false]}
      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "!trim"
    end

    test "renders precision millisecond", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{
        name: :ts,
        type: :utc_datetime,
        constraints: [precision: :millisecond]
      }

      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "precision: millisecond"
    end

    test "renders precision second", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{
        name: :ts,
        type: :utc_datetime,
        constraints: [precision: :second]
      }

      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "precision: second"
    end

    test "renders generic constraint with key-value", %{terminal: terminal, area: area} do
      attr = %AttributeInfo{
        name: :score,
        type: :integer,
        constraints: [max: 100]
      }

      widgets = AttributeDetail.render(attr, area)
      :ok = ExRatatui.draw(terminal, widgets)
      content = ExRatatui.get_buffer_content(terminal)

      assert content =~ "max: 100"
    end
  end
end
