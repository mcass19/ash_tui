defmodule AshDemo.Accounts.Token do
  use Ash.Resource,
    domain: AshDemo.Accounts,
    data_layer: Ash.DataLayer.Ets

  attributes do
    uuid_primary_key :id

    attribute :purpose, :atom do
      constraints one_of: [:session, :password_reset, :email_confirmation]
      allow_nil? false
      public? true
    end

    attribute :expires_at, :utc_datetime do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:purpose, :expires_at]
      primary? true
    end
  end

  relationships do
    belongs_to :user, AshDemo.Accounts.User do
      allow_nil? false
      public? true
    end
  end
end
