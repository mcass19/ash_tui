defmodule AshTui.Introspection.ArgumentInfo do
  @moduledoc "Holds introspection data for an action argument."

  defstruct [:name, :type, allow_nil?: true]

  @type t :: %__MODULE__{
          name: atom(),
          type: atom() | {:array, atom()},
          allow_nil?: boolean()
        }
end
