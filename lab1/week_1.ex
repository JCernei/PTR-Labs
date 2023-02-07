defmodule Greeter do
  def hello do
    "Hello PTR"
  end

  def start do
    IO.puts(hello())
  end
end

Greeter.start()
