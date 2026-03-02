defmodule AshTui.IntrospectionTest do
  use ExUnit.Case, async: true

  alias AshTui.Introspection

  alias AshTui.Introspection.{
    ActionInfo,
    AttributeInfo,
    DomainInfo,
    RelationshipInfo,
    ResourceInfo
  }

  alias AshTui.Test.Fixtures

  doctest AshTui.Introspection

  describe "from_data/1" do
    test "creates domain info structs" do
      domains = Fixtures.sample_domains()

      assert length(domains) == 2
      assert [%DomainInfo{name: Test.Accounts}, %DomainInfo{name: Test.Blog}] = domains
    end

    test "creates resource info with attributes" do
      [accounts | _] = Fixtures.sample_domains()
      [user | _] = accounts.resources

      assert %ResourceInfo{name: Test.Accounts.User, domain: Test.Accounts} = user
      assert length(user.attributes) == 4

      email = Enum.find(user.attributes, &(&1.name == :email))
      assert %AttributeInfo{type: :ci_string, allow_nil?: false} = email
    end

    test "extracts primary keys from attributes" do
      [accounts | _] = Fixtures.sample_domains()
      [user | _] = accounts.resources

      assert user.primary_key == [:id]
    end

    test "creates action info with arguments" do
      [accounts | _] = Fixtures.sample_domains()
      [user | _] = accounts.resources

      create_action = Enum.find(user.actions, &(&1.name == :create))
      assert %ActionInfo{type: :create, primary?: true} = create_action
      assert length(create_action.arguments) == 2

      email_arg = Enum.find(create_action.arguments, &(&1.name == :email))
      assert email_arg.type == :ci_string
      assert email_arg.allow_nil? == false
    end

    test "creates relationship info" do
      [accounts | _] = Fixtures.sample_domains()
      [user | _] = accounts.resources

      posts_rel = Enum.find(user.relationships, &(&1.name == :posts))
      assert %RelationshipInfo{type: :has_many, destination: Test.Blog.Post} = posts_rel
    end

    test "handles empty data" do
      assert Introspection.from_data([]) == []
    end

    test "handles resources with no relationships" do
      domains =
        Introspection.from_data([
          %{
            name: Test.Simple,
            resources: [
              %{
                name: Test.Simple.Item,
                attributes: [%{name: :id, type: :uuid, primary_key?: true}],
                actions: [%{name: :read, type: :read, primary?: true}]
              }
            ]
          }
        ])

      [domain] = domains
      [resource] = domain.resources

      assert resource.relationships == []
      assert resource.name == Test.Simple.Item
    end
  end
end
