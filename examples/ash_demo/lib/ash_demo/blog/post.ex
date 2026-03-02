defmodule AshDemo.Blog.Post do
  use Ash.Resource,
    domain: AshDemo.Blog,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :body, :string do
      allow_nil? false
      public? true
    end

    attribute :status, :atom do
      constraints one_of: [:draft, :published, :archived]
      default :draft
      public? true
    end

    attribute :published_at, :utc_datetime do
      public? true
    end

    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:title, :body, :status]
      primary? true
    end

    update :update do
      accept [:title, :body]
      primary? true
    end

    update :publish do
      accept []

      change set_attribute(:status, :published)
      change set_attribute(:published_at, &DateTime.utc_now/0)
    end

    update :archive do
      accept []
      change set_attribute(:status, :archived)
    end
  end

  relationships do
    belongs_to :author, AshDemo.Accounts.User do
      public? true
    end

    has_many :comments, AshDemo.Blog.Comment do
      public? true
    end

    many_to_many :tags, AshDemo.Blog.Tag do
      through AshDemo.Blog.PostTag
      source_attribute_on_join_resource :post_id
      destination_attribute_on_join_resource :tag_id
      public? true
    end
  end
end
