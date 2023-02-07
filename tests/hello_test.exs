ExUnit.start()

defmodule TestHello do
  use ExUnit.Case
  import ExUnit.CaptureIO
  Code.require_file("./lab1/week_1.ex")

  test "returns Hello PTR" do
    assert Greeter.hello() == "Hello PTR"
  end

  test "outputs Hello PTR" do
    assert capture_io(fn -> Greeter.start() end) == "Hello PTR\n"
  end
end
