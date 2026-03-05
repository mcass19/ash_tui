defmodule AshTui.Introspection.AttributeInfo do
  @moduledoc "Holds introspection data for a resource attribute."

  defstruct [
    :name,
    :type,
    allow_nil?: true,
    primary_key?: false,
    generated?: false,
    constraints: []
  ]

  @type t :: %__MODULE__{
          name: atom(),
          type: atom() | {:array, atom()},
          allow_nil?: boolean(),
          primary_key?: boolean(),
          generated?: boolean(),
          constraints: keyword()
        }
end
