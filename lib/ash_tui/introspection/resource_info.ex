defmodule AshTui.Introspection.ResourceInfo do
  @moduledoc "Holds introspection data for a single Ash resource."

  defstruct [:name, :domain, primary_key: [], attributes: [], actions: [], relationships: []]

  @type t :: %__MODULE__{
          name: atom(),
          domain: atom(),
          primary_key: [atom()],
          attributes: [AshTui.Introspection.AttributeInfo.t()],
          actions: [AshTui.Introspection.ActionInfo.t()],
          relationships: [AshTui.Introspection.RelationshipInfo.t()]
        }
end
