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

    test "preserves attribute constraints through from_data/1" do
      [accounts | _] = Fixtures.sample_domains()
      [user | _] = accounts.resources

      email = Enum.find(user.attributes, &(&1.name == :email))
      assert email.constraints == [trim?: true, allow_empty?: false]

      name = Enum.find(user.attributes, &(&1.name == :name))
      assert name.constraints == [trim?: true]

      role = Enum.find(user.attributes, &(&1.name == :role))
      assert role.constraints == [one_of: [:admin, :user, :moderator]]
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

  describe "load/1" do
    setup do
      Application.put_env(:ash_tui_introspection_test, :ash_domains, [AshTui.Test.TestDomain])

      on_exit(fn ->
        Application.delete_env(:ash_tui_introspection_test, :ash_domains)
      end)
    end

    test "loads real Ash domains" do
      domains = Introspection.load(:ash_tui_introspection_test)

      assert [%DomainInfo{name: AshTui.Test.TestDomain}] = domains
    end

    test "loads resources with attributes" do
      [domain] = Introspection.load(:ash_tui_introspection_test)

      author = Enum.find(domain.resources, &(&1.name == AshTui.Test.Author))
      assert %ResourceInfo{domain: AshTui.Test.TestDomain} = author
      assert length(author.attributes) >= 2

      id_attr = Enum.find(author.attributes, &(&1.name == :id))
      assert %AttributeInfo{primary_key?: true} = id_attr

      name_attr = Enum.find(author.attributes, &(&1.name == :name))
      assert %AttributeInfo{allow_nil?: false} = name_attr
    end

    test "extracts primary keys from real resources" do
      [domain] = Introspection.load(:ash_tui_introspection_test)
      author = Enum.find(domain.resources, &(&1.name == AshTui.Test.Author))
      assert :id in author.primary_key
    end

    test "loads actions with arguments" do
      [domain] = Introspection.load(:ash_tui_introspection_test)
      author = Enum.find(domain.resources, &(&1.name == AshTui.Test.Author))

      create = Enum.find(author.actions, &(&1.name == :create))
      assert %ActionInfo{type: :create} = create
      assert length(create.arguments) >= 1

      email_arg = Enum.find(create.arguments, &(&1.name == :email))
      assert email_arg.allow_nil? == false
    end

    test "loads relationships" do
      [domain] = Introspection.load(:ash_tui_introspection_test)
      author = Enum.find(domain.resources, &(&1.name == AshTui.Test.Author))

      posts_rel = Enum.find(author.relationships, &(&1.name == :posts))
      assert %RelationshipInfo{type: :has_many, destination: AshTui.Test.Post} = posts_rel
    end

    test "returns empty list when no domains configured" do
      assert Introspection.load(:ash_tui_unconfigured_app) == []
    end
  end
end
