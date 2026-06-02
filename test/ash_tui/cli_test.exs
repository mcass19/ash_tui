defmodule AshTui.CLITest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  # Records the launch call instead of booting a terminal.
  defp recording_launcher do
    test = self()
    fn otp_app, opts -> send(test, {:launched, otp_app, opts}) end
  end

  describe "main/2 transport selection" do
    test "local launches with no transport and prints no banner" do
      output = capture_io(fn -> AshTui.CLI.main([], recording_launcher()) end)

      assert_received {:launched, :ash_tui, []}
      assert output == ""
    end

    test "ssh applies defaults and prints the SSH banner" do
      banner = capture_io(fn -> AshTui.CLI.main(["--ssh"], recording_launcher()) end)

      assert_received {:launched, :ash_tui, opts}
      assert opts[:transport] == :ssh
      assert banner =~ "SSH on port 2222"
    end

    test "ssh honors --port" do
      banner =
        capture_io(fn -> AshTui.CLI.main(["--ssh", "--port", "4000"], recording_launcher()) end)

      assert_received {:launched, :ash_tui, opts}
      assert opts[:port] == 4000
      assert banner =~ "port 4000"
    end

    test "distributed prints the distribution banner" do
      banner = capture_io(fn -> AshTui.CLI.main(["--distributed"], recording_launcher()) end)

      assert_received {:launched, :ash_tui, opts}
      assert opts[:transport] == :distributed
      assert banner =~ "distribution connections"
    end
  end

  describe "main/2 otp_app resolution" do
    test "defaults to the mix project app" do
      capture_io(fn -> AshTui.CLI.main([], recording_launcher()) end)
      assert_received {:launched, :ash_tui, _}
    end

    test "resolves --otp-app to an existing atom" do
      capture_io(fn -> AshTui.CLI.main(["--otp-app", "ash_tui"], recording_launcher()) end)
      assert_received {:launched, :ash_tui, _}
    end
  end

  test "raises on unknown flags" do
    assert_raise OptionParser.ParseError, fn ->
      AshTui.CLI.main(["--nope"], recording_launcher())
    end
  end
end
