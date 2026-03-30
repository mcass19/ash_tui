defmodule AshTui.Test.Post do
  @moduledoc false
  use Ash.Resource, domain: AshTui.Test.TestDomain

  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, allow_nil?: false, public?: true)
  end

  actions do
    default_accept(:*)
    defaults([:read, :create])
  end

  relationships do
    belongs_to(:author, AshTui.Test.Author, public?: true)
  end
end
