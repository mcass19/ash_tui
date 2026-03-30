defmodule AshTui.Introspection.ArgumentInfo do
  @moduledoc """
  Holds introspection data for an action argument.

  ## Fields

    * `:name` - the argument name atom (e.g. `:email`)
    * `:type` - the Ash type (atom or `{:array, atom()}`)
    * `:allow_nil?` - whether `nil` values are accepted (default `true`)
  """

  defstruct [:name, :type, allow_nil?: true]

  @type t :: %__MODULE__{
          name: atom(),
          type: atom() | {:array, atom()},
          allow_nil?: boolean()
        }
end
