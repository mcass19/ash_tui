defmodule AshTui.MixTaskTest do
  use ExUnit.Case, async: true

  @strict [otp_app: :string, ssh: :boolean, distributed: :boolean, port: :integer]

  describe "option parsing" do
    test "parses --otp-app flag" do
      {opts, _rest} = OptionParser.parse!(["--otp-app", "my_app"], strict: @strict)
      assert Keyword.get(opts, :otp_app) == "my_app"
    end

    test "defaults to nil when no --otp-app given" do
      {opts, _rest} = OptionParser.parse!([], strict: @strict)
      assert Keyword.get(opts, :otp_app) == nil
    end

    test "parses --ssh flag" do
      {opts, _rest} = OptionParser.parse!(["--ssh"], strict: @strict)
      assert opts[:ssh] == true
    end

    test "parses --distributed flag" do
      {opts, _rest} = OptionParser.parse!(["--distributed"], strict: @strict)
      assert opts[:distributed] == true
    end

    test "parses --ssh with --port" do
      {opts, _rest} = OptionParser.parse!(["--ssh", "--port", "4000"], strict: @strict)
      assert opts[:ssh] == true
      assert opts[:port] == 4000
    end

    test "raises on unknown flags" do
      assert_raise OptionParser.ParseError, fn ->
        OptionParser.parse!(["--unknown", "val"], strict: @strict)
      end
    end
  end
end
