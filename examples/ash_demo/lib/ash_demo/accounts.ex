defmodule AshDemo.Accounts do
  use Ash.Domain

  resources do
    resource AshDemo.Accounts.User
    resource AshDemo.Accounts.Token
  end
end
