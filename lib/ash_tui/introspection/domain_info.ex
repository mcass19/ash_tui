defmodule AshTui.Introspection.DomainInfo do
  @moduledoc """
  Holds introspection data for a single Ash domain.

  ## Fields

    * `:name` - the domain module atom (e.g. `MyApp.Accounts`)
    * `:resources` - list of `%AshTui.Introspection.ResourceInfo{}` structs
  """

  defstruct [:name, resources: []]

  @type t :: %__MODULE__{
          name: atom(),
          resources: [AshTui.Introspection.ResourceInfo.t()]
        }
end
