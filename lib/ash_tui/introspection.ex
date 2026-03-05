defmodule AshTui.Introspection do
  @moduledoc """
  Loads Ash domain and resource metadata into a navigable data structure.

  All data comes from Ash's compile-time introspection API. No database
  connection is needed — this reads the *shape* of an app, not its data.
  """

  alias __MODULE__.{
    ActionInfo,
    ArgumentInfo,
    AttributeInfo,
    DomainInfo,
    RelationshipInfo,
    ResourceInfo
  }

  @doc """
  Loads all Ash domains and their resources for the given OTP app.

  Returns a list of `DomainInfo` structs, each containing its resources
  with fully loaded attributes, actions, and relationships.
  """
  @spec load(atom()) :: [DomainInfo.t()]
  def load(otp_app) do
    otp_app
    |> Ash.Info.domains()
    |> Enum.map(&load_domain/1)
  end

  @doc """
  Creates introspection data from a pre-built list of domain info maps.

  Useful for testing without requiring a real Ash application.

  ## Examples

      iex> [domain] = AshTui.Introspection.from_data([
      ...>   %{
      ...>     name: MyApp.Accounts,
      ...>     resources: [
      ...>       %{
      ...>         name: MyApp.Accounts.User,
      ...>         attributes: [%{name: :id, type: :uuid, primary_key?: true}],
      ...>         actions: [%{name: :read, type: :read, primary?: true}],
      ...>         relationships: []
      ...>       }
      ...>     ]
      ...>   }
      ...> ])
      iex> domain.name
      MyApp.Accounts
      iex> [resource] = domain.resources
      iex> resource.name
      MyApp.Accounts.User
      iex> resource.primary_key
      [:id]
  """
  @spec from_data([map()]) :: [DomainInfo.t()]
  def from_data(domains) when is_list(domains) do
    Enum.map(domains, fn domain ->
      resources =
        Enum.map(domain.resources, fn resource ->
          %ResourceInfo{
            name: resource.name,
            domain: domain.name,
            primary_key: extract_primary_keys(resource),
            attributes: Enum.map(Map.get(resource, :attributes, []), &struct!(AttributeInfo, &1)),
            actions:
              Enum.map(Map.get(resource, :actions, []), fn action ->
                arguments = Enum.map(Map.get(action, :arguments, []), &struct!(ArgumentInfo, &1))
                struct!(ActionInfo, Map.put(action, :arguments, arguments))
              end),
            relationships:
              Enum.map(Map.get(resource, :relationships, []), &struct!(RelationshipInfo, &1))
          }
        end)

      %DomainInfo{name: domain.name, resources: resources}
    end)
  end

  # ── Private ──────────────────────────────────────────────────

  defp load_domain(domain) do
    resources =
      domain
      |> Ash.Domain.Info.resources()
      |> Enum.map(&load_resource(&1, domain))

    %DomainInfo{name: domain, resources: resources}
  end

  defp load_resource(resource, domain) do
    %ResourceInfo{
      name: resource,
      domain: domain,
      primary_key: Ash.Resource.Info.primary_key(resource),
      attributes: load_attributes(resource),
      actions: load_actions(resource),
      relationships: load_relationships(resource)
    }
  end

  defp load_attributes(resource) do
    resource
    |> Ash.Resource.Info.attributes()
    |> Enum.map(fn attr ->
      %AttributeInfo{
        name: attr.name,
        type: attr.type,
        allow_nil?: attr.allow_nil?,
        primary_key?: attr.primary_key?,
        generated?: attr.generated?,
        constraints: attr.constraints
      }
    end)
  end

  defp load_actions(resource) do
    resource
    |> Ash.Resource.Info.actions()
    |> Enum.map(fn action ->
      %ActionInfo{
        name: action.name,
        type: action.type,
        primary?: action.primary?,
        arguments: load_arguments(action)
      }
    end)
  end

  defp load_arguments(action) do
    action.arguments
    |> Enum.map(fn arg ->
      %ArgumentInfo{
        name: arg.name,
        type: arg.type,
        allow_nil?: arg.allow_nil?
      }
    end)
  end

  defp load_relationships(resource) do
    resource
    |> Ash.Resource.Info.relationships()
    |> Enum.map(fn rel ->
      %RelationshipInfo{
        name: rel.name,
        type: rel.type,
        destination: rel.destination
      }
    end)
  end

  defp extract_primary_keys(resource) do
    resource
    |> Map.get(:attributes, [])
    |> Enum.filter(&Map.get(&1, :primary_key?, false))
    |> Enum.map(& &1.name)
  end
end
