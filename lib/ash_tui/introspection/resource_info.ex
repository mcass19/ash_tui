defmodule AshTui.Introspection.ResourceInfo do
  @moduledoc """
  Holds introspection data for a single Ash resource.

  ## Fields

    * `:name` - the resource module atom (e.g. `MyApp.Accounts.User`)
    * `:domain` - the parent domain module atom
    * `:primary_key` - list of attribute names forming the primary key
    * `:attributes` - list of `%AshTui.Introspection.AttributeInfo{}` structs
    * `:actions` - list of `%AshTui.Introspection.ActionInfo{}` structs
    * `:relationships` - list of `%AshTui.Introspection.RelationshipInfo{}` structs
  """

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
