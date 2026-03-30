defmodule AshTui.Introspection.AttributeInfo do
  @moduledoc """
  Holds introspection data for a resource attribute.

  ## Fields

    * `:name` - the attribute name atom (e.g. `:email`)
    * `:type` - the Ash type (atom or `{:array, atom()}`)
    * `:allow_nil?` - whether `nil` values are accepted (default `true`)
    * `:primary_key?` - whether this attribute is part of the primary key (default `false`)
    * `:generated?` - whether the value is auto-generated (default `false`)
    * `:constraints` - keyword list of type constraints (e.g. `[trim?: true]`)
  """

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
