defmodule AshTui.Test.Fixtures do
  @moduledoc false

  alias AshTui.Introspection

  @doc """
  Returns sample introspection data with two domains and cross-domain relationships.
  """
  def sample_domains do
    Introspection.from_data([
      %{
        name: Test.Accounts,
        resources: [
          %{
            name: Test.Accounts.User,
            attributes: [
              %{name: :id, type: :uuid, primary_key?: true, generated?: true},
              %{name: :email, type: :ci_string, allow_nil?: false},
              %{name: :name, type: :string},
              %{name: :role, type: :atom}
            ],
            actions: [
              %{name: :read, type: :read, primary?: true},
              %{
                name: :create,
                type: :create,
                primary?: true,
                arguments: [
                  %{name: :email, type: :ci_string, allow_nil?: false},
                  %{name: :name, type: :string}
                ]
              },
              %{name: :destroy, type: :destroy, primary?: true}
            ],
            relationships: [
              %{name: :posts, type: :has_many, destination: Test.Blog.Post},
              %{name: :tokens, type: :has_many, destination: Test.Accounts.Token}
            ]
          },
          %{
            name: Test.Accounts.Token,
            attributes: [
              %{name: :id, type: :uuid, primary_key?: true, generated?: true},
              %{name: :purpose, type: :atom, allow_nil?: false}
            ],
            actions: [
              %{name: :read, type: :read, primary?: true},
              %{name: :create, type: :create, primary?: true}
            ],
            relationships: [
              %{name: :user, type: :belongs_to, destination: Test.Accounts.User}
            ]
          }
        ]
      },
      %{
        name: Test.Blog,
        resources: [
          %{
            name: Test.Blog.Post,
            attributes: [
              %{name: :id, type: :uuid, primary_key?: true, generated?: true},
              %{name: :title, type: :string, allow_nil?: false},
              %{name: :body, type: :string, allow_nil?: false}
            ],
            actions: [
              %{name: :read, type: :read, primary?: true},
              %{name: :create, type: :create, primary?: true},
              %{name: :publish, type: :update}
            ],
            relationships: [
              %{name: :author, type: :belongs_to, destination: Test.Accounts.User}
            ]
          }
        ]
      }
    ])
  end
end
