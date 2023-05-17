defmodule PubSub do
  @local_host {127, 0, 0, 1}

  def start() do
    IO.puts("p - publish, s - subscribe, u - unsubscribe, enter - receive")
    # create a socket with random port
    server = Socket.UDP.open!()
    pid_self = self()

    spawn(fn ->
      listen(server, pid_self)
    end)

    user_IO(server)
  end

  def listen(server, pid_self) do
    {:ok, data} = server |> Socket.Datagram.recv(1024)
    {message, _addres_and_port} = data
    send(pid_self, message)
    listen(server, pid_self)
  end

  def user_IO(server) do
    receive do
      message -> IO.puts("RECEIVED: #{message}")
    after
      100 -> IO.write("")
    end

    {command, topic, message} = parse_input()

    cond do
      command == nil or topic == nil -> ""
      String.downcase(command) == "p" -> publish(server, topic, message)
      String.downcase(command) == "s" -> subscribe(server, topic)
      String.downcase(command) == "u" -> unsubscribe(server, topic)
      true -> IO.puts("Something's wrong")
    end

    user_IO(server)
  end

  def parse_input() do
    input = IO.gets("P|S|U topic message:")
    input = String.replace(input, "\n", "")
    input_parts = String.split(input, " ", trim: true, parts: 3)

    {command, input_parts} = List.pop_at(input_parts, 0)
    {topic, input_parts} = List.pop_at(input_parts, 0)
    {message, _} = List.pop_at(input_parts, 0)
    {command, topic, message}
  end

  def subscribe(server, topic) do
    Socket.Datagram.send!(server, "Subscribe,#{topic}", {@local_host, 10001})
  end

  def unsubscribe(server, topic) do
    Socket.Datagram.send!(server, "UnSubscribe,#{topic}", {@local_host, 10001})
  end

  def publish(server, topic, data) do
    Socket.Datagram.send!(server, "Publish,#{topic},#{data}", {@local_host, 10002})
  end
end

PubSub.start()
