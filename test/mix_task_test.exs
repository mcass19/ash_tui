defmodule AshTui.MixTaskTest do
  use ExUnit.Case, async: true

  describe "option parsing" do
    test "parses --otp-app flag" do
      {opts, _rest} = OptionParser.parse!(["--otp-app", "my_app"], strict: [otp_app: :string])
      assert Keyword.get(opts, :otp_app) == "my_app"
    end

    test "defaults to nil when no --otp-app given" do
      {opts, _rest} = OptionParser.parse!([], strict: [otp_app: :string])
      assert Keyword.get(opts, :otp_app) == nil
    end

    test "raises on unknown flags" do
      assert_raise OptionParser.ParseError, fn ->
        OptionParser.parse!(["--unknown", "val"], strict: [otp_app: :string])
      end
    end
  end
end
