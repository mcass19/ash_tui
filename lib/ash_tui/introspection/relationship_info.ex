defmodule AshTui.Introspection.RelationshipInfo do
  @moduledoc """
  Holds introspection data for a resource relationship.

  ## Fields

    * `:name` - the relationship name atom (e.g. `:posts`)
    * `:type` - one of `:belongs_to`, `:has_one`, `:has_many`, or `:many_to_many`
    * `:destination` - the destination resource module atom
  """

  defstruct [:name, :type, :destination]

  @type t :: %__MODULE__{
          name: atom(),
          type: :belongs_to | :has_one | :has_many | :many_to_many,
          destination: atom()
        }
end
