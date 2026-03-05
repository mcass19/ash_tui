defmodule AshTui.Format do
  @moduledoc """
  Shared formatting helpers for display in the TUI.
  """

  @doc """
  Returns the last segment of a module name.

  ## Examples

      iex> AshTui.Format.short_name(MyApp.Accounts.User)
      "User"

      iex> AshTui.Format.short_name(MyApp.Blog)
      "Blog"
  """
  @spec short_name(atom()) :: String.t()
  def short_name(module) when is_atom(module) do
    module
    |> Module.split()
    |> List.last()
  end

  @doc """
  Formats an Ash type for display, stripping common prefixes.

  ## Examples

      iex> AshTui.Format.format_type(:string)
      "string"

      iex> AshTui.Format.format_type({:array, :string})
      "[string]"
  """
  @spec format_type(atom() | {:array, atom()} | term()) :: String.t()
  def format_type(type) when is_atom(type) do
    type
    |> Atom.to_string()
    |> strip_type_prefix()
  end

  def format_type({:array, inner}), do: "[#{format_type(inner)}]"

  def format_type(type) do
    type
    |> inspect()
    |> strip_type_prefix()
  end

  defp strip_type_prefix("Elixir.Ash.Type." <> rest), do: rest
  defp strip_type_prefix("Elixir." <> rest), do: rest
  defp strip_type_prefix(other), do: other
end
