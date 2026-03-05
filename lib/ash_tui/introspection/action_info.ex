defmodule AshTui.Introspection.ActionInfo do
  @moduledoc "Holds introspection data for a resource action."

  defstruct [:name, :type, primary?: false, arguments: []]

  @type t :: %__MODULE__{
          name: atom(),
          type: atom(),
          primary?: boolean(),
          arguments: [AshTui.Introspection.ArgumentInfo.t()]
        }
end
