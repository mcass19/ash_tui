defmodule AshTui.Introspection.ActionInfo do
  @moduledoc """
  Holds introspection data for a resource action.

  ## Fields

    * `:name` - the action name atom (e.g. `:create`)
    * `:type` - the action type (`:create`, `:read`, `:update`, or `:destroy`)
    * `:primary?` - whether this is the primary action for its type (default `false`)
    * `:arguments` - list of `%AshTui.Introspection.ArgumentInfo{}` structs
  """

  defstruct [:name, :type, primary?: false, arguments: []]

  @type t :: %__MODULE__{
          name: atom(),
          type: atom(),
          primary?: boolean(),
          arguments: [AshTui.Introspection.ArgumentInfo.t()]
        }
end
