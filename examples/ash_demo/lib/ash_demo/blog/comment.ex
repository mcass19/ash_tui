defmodule AshDemo.Blog.Comment do
  use Ash.Resource,
    domain: AshDemo.Blog,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id

    attribute :body, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:body]
      primary? true
    end

    update :update do
      accept [:body]
      primary? true
    end
  end

  relationships do
    belongs_to :post, AshDemo.Blog.Post do
      allow_nil? false
      public? true
    end

    belongs_to :author, AshDemo.Accounts.User do
      public? true
    end
  end
end
