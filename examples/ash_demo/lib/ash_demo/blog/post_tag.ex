defmodule AshDemo.Blog.PostTag do
  use Ash.Resource,
    domain: AshDemo.Blog,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id
    timestamps()
  end

  actions do
    defaults [:read, :destroy, :create]
  end

  relationships do
    belongs_to :post, AshDemo.Blog.Post do
      allow_nil? false
      public? true
    end

    belongs_to :tag, AshDemo.Blog.Tag do
      allow_nil? false
      public? true
    end
  end
end
