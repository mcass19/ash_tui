defmodule AshTui.FormatTest do
  use ExUnit.Case, async: true

  doctest AshTui.Format

  alias AshTui.Format

  describe "short_name/1" do
    test "extracts last segment of deeply nested module" do
      assert Format.short_name(MyApp.Accounts.Admin.User) == "User"
    end

    test "handles single-segment module" do
      assert Format.short_name(TopLevel) == "TopLevel"
    end
  end

  describe "format_type/1" do
    test "strips Ash.Type prefix" do
      assert Format.format_type(Ash.Type.CiString) == "CiString"
    end

    test "strips Elixir prefix from non-Ash modules" do
      assert Format.format_type(MyApp.CustomType) == "MyApp.CustomType"
    end

    test "handles nested array types" do
      assert Format.format_type({:array, {:array, :string}}) == "[[string]]"
    end

    test "handles non-atom types via inspect" do
      assert is_binary(Format.format_type({:parameterized, :some, :thing}))
    end
  end
end
