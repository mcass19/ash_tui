defmodule AshTui.Introspection.RelationshipInfo do
  @moduledoc "Holds introspection data for a resource relationship."

  defstruct [:name, :type, :destination]

  @type t :: %__MODULE__{
          name: atom(),
          type: :belongs_to | :has_one | :has_many | :many_to_many,
          destination: atom()
        }
end
