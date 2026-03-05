defmodule AshTui.Introspection.DomainInfo do
  @moduledoc "Holds introspection data for a single Ash domain."

  defstruct [:name, resources: []]

  @type t :: %__MODULE__{
          name: atom(),
          resources: [AshTui.Introspection.ResourceInfo.t()]
        }
end
