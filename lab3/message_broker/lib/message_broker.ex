defmodule RedisActor do
  require Redix

  defp redis_command(command) do
    {:ok, conn} = Redix.start_link()

    IO.puts("The command is #{inspect(command)}")

    case Redix.command(conn, command) do
      {:ok, response} ->
        {:ok, response}

      _ ->
        IO.puts("error")
        :error
    end
  end

  def get_publications(topic) do
    redis_command(["HGET", "messages", topic])
  end

  def set_publication(topic, message) do
    redis_command(["HSET", "messages", topic, message])
  end

  def append_key_value(key, value) do
    redis_command(["RPUSH", key, value])
  end

  def delete_key(key) do
    redis_command(["DEL", key])
  end

  def delete_key_value(key, value) do
    case redis_command(["TYPE", key]) do
      {:ok, "list"} ->
        redis_command(["LREM", key, "0", value])

      {:ok, "set"} ->
        redis_command(["SREM", key, value])

      {:ok, "string"} ->
        IO.puts("hahaha")
        redis_command(["DEL", key])

      {:ok, "none"} ->
        {:ok, nil}

      _ ->
        :error
    end
  end

  def get_key_values(key) do
    case redis_command(["TYPE", key]) do
      {:ok, "list"} ->
        redis_command(["LRANGE", key, "0", "-1"])

      {:ok, "set"} ->
        redis_command(["SMEMBERS", key])

      {:ok, "string"} ->
        [redis_command(["GET", key])]

      {:ok, "none"} ->
        {:ok, nil}

      _ ->
        :error
    end
  end
end

defmodule Filter do
  def get_subscribers(topic_name) do
    case RedisActor.get_key_values(topic_name) do
      {:ok, nil} -> nil
      {:ok, subscribers} -> subscribers
      _ -> nil
    end
  end

  def add_subscriber(topic_name, subscriber_end_point) do
    IO.puts("Entered add sub")

    case RedisActor.get_key_values(topic_name) do
      {:ok, nil} ->
        IO.puts("This topic has no subscribers")
        RedisActor.append_key_value(topic_name, subscriber_end_point)

      {:ok, values} ->
        unless Enum.member?(values, subscriber_end_point) do
          IO.puts("APPEND subscriber")
          RedisActor.append_key_value(topic_name, subscriber_end_point)
        else
          IO.puts("You are already subscribed")
        end

      _ ->
        IO.puts("You are already subscribed")
        :ok
    end
  end

  def remove_subscriber(topic_name, subscriber_end_point) do
    IO.puts("Endtered remove sub")
    IO.puts("asdasdasd")

    case RedisActor.get_key_values(topic_name) do
      {:ok, nil} ->
        IO.puts("You are not subscribed to this topic")
        :ok

      {:ok, values} ->
        IO.puts("UNSUBSCRIBE")

        if Enum.member?(values, subscriber_end_point) do
          RedisActor.delete_key_value(topic_name, subscriber_end_point)
        end

        :ok

      _ ->
        IO.puts("Something went wrong")
        :ok
    end
  end
end

defmodule SubscriberService do
  def start() do
    spawn(&host/0)
  end

  defp host() do
    IO.puts("starting SubscribeService")
    {:ok, socket} = Socket.UDP.open(10001)
    IO.puts(inspect(socket))
    listen(socket)
  end

  defp listen(socket) do
    loop(socket)
  end

  defp loop(socket) do
    case Socket.Datagram.Protocol.recv(socket, 1024) do
      {:ok, data} ->
        IO.inspect(data)
        {message, addres_and_port} = data
        message_parts = String.split(message, ",", trim: true)

        case message_parts do
          [command, topic | _rest] ->
            case command do
              "Subscribe" ->
                Filter.add_subscriber(topic, inspect(addres_and_port))

              "UnSubscribe" ->
                Filter.remove_subscriber(topic, inspect(addres_and_port))

              _ ->
                :ok
            end

          _ ->
            :ok
        end

        loop(socket)

      {:error, _reason} ->
        loop(socket)
    end
  end
end

defmodule PublisherService do
  def start() do
    spawn(&host/0)
  end

  defp host() do
    IO.puts("starting PublisherService")
    {:ok, socket} = Socket.UDP.open(10002)
    IO.puts(inspect(socket))
    listen(socket)
  end

  defp listen(socket) do
    loop(socket)
  end

  defp loop(socket) do
    case Socket.Datagram.Protocol.recv(socket, 1024) do
      {:ok, data} ->
        IO.inspect(data)
        {message, _addres_and_port} = data
        message_parts = String.split(message, ",", trim: true)

        case message_parts do
          [command, topic, message | _rest] ->
            IO.inspect(command)

            if command == "Publish" && !(topic == "") do
              IO.puts("publishing")

              subscribers_list = Filter.get_subscribers(topic)

              case subscribers_list do
                nil ->
                  case RedisActor.get_publications(topic) do
                    {:ok, nil} ->
                      {:ok, result} = RedisActor.set_publication(topic, message)
                      IO.puts("new topic #{result}")

                    {:ok, current_value} ->
                      updated_value = "#{current_value},#{message}"
                      {:ok, result} = RedisActor.set_publication(topic, updated_value)
                      IO.puts("new topic #{result}")
                  end

                _ ->
                  case RedisActor.get_publications(topic) do
                    {:ok, nil} ->
                      {:ok, result} = RedisActor.set_publication(topic, message)
                      IO.puts("new topic #{result}")

                      Enum.each(subscribers_list, fn end_point ->
                        Socket.Datagram.send!(socket, message, Code.eval_string(end_point))
                      end)

                    {:ok, current_value} ->
                      updated_value = "#{current_value},#{message}"
                      {:ok, result} = RedisActor.set_publication(topic, updated_value)
                      IO.puts("new topic #{result}")

                      messages = String.split(updated_value, ",", trim: true)

                      Enum.each(
                        messages,
                        fn a_message ->
                          Enum.each(subscribers_list, fn end_point ->
                            IO.puts("Sending the message to subscriber")

                            Socket.Datagram.send!(
                              socket,
                              a_message,
                              Code.eval_string(end_point)
                            )
                          end)
                        end
                      )
                  end
              end
            end

          _ ->
            :ok
        end

        loop(socket)

      {:error, _reason} ->
        loop(socket)
    end
  end
end

defmodule MessageBroker do
  def main(_args) do
    PublisherService.start()
    SubscriberService.start()
    loop()
  end

  defp loop() do
    receive do
      {:message_type, _value} ->
        :ok
    end

    loop()
  end
end
