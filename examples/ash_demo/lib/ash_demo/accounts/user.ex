defmodule AshDemo.Accounts.User do
  use Ash.Resource,
    domain: AshDemo.Accounts,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :name, :string do
      public? true
    end

    attribute :role, :atom do
      constraints one_of: [:admin, :editor, :viewer]
      default :viewer
      public? true
    end

    attribute :bio, :string do
      public? true
    end

    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :register do
      accept [:email, :name, :role, :bio]
      primary? true
    end

    update :update_profile do
      accept [:name, :bio]
      primary? true
    end

    update :change_role do
      accept [:role]
    end
  end

  relationships do
    has_many :tokens, AshDemo.Accounts.Token do
      public? true
    end

    has_many :posts, AshDemo.Blog.Post do
      destination_attribute :author_id
      public? true
    end

    has_many :comments, AshDemo.Blog.Comment do
      destination_attribute :author_id
      public? true
    end
  end
end
