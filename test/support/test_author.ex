defmodule AshTui.Test.Author do
  @moduledoc false
  use Ash.Resource, domain: AshTui.Test.TestDomain

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false, public?: true)
  end

  actions do
    default_accept(:*)
    defaults([:read, :destroy])

    create :create do
      argument(:email, :string, allow_nil?: false)
    end
  end

  relationships do
    has_many(:posts, AshTui.Test.Post)
  end
end
