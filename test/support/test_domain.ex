defmodule AshTui.Test.TestDomain do
  @moduledoc false
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(AshTui.Test.Author)
    resource(AshTui.Test.Post)
  end
end
