defmodule AshDemo.Blog.Tag do
  use Ash.Resource,
    domain: AshDemo.Blog,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :slug, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:name, :slug]
      primary? true
    end
  end

  relationships do
    many_to_many :posts, AshDemo.Blog.Post do
      through AshDemo.Blog.PostTag
      source_attribute_on_join_resource :tag_id
      destination_attribute_on_join_resource :post_id
      public? true
    end
  end
end
