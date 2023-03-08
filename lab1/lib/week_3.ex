defmodule PrinterActor do
  def start do
    spawn(fn -> loop() end)
  end

  def loop do
    receive do
      msg -> IO.inspect(msg)
    end

    loop()
  end
end

printer_actor = PrinterActor.start()
send(printer_actor, "hahahhahahahah!")
send(printer_actor, "what?")

defmodule ModifyActor do
  def start do
    spawn(fn -> loop() end)
  end

  def loop do
    receive do
      msg ->
        if is_integer(msg) do
          IO.puts("Received: #{msg + 1}")
        else
          if is_binary(msg) do
            IO.puts("Received: #{msg |> String.trim() |> String.upcase()}")
          else
            IO.puts("Received: I don’t know how to handle this!")
          end
        end
    end

    loop()
  end
end

modify_actor = ModifyActor.start()
send(modify_actor, 164_540)
send(modify_actor, "Hello")
send(modify_actor, [10, "Hello"])

defmodule MonitoredActor do
  def start do
    spawn(fn ->
      IO.puts("Monitored Actor says: Finished!")
      Process.exit(self(), :kill)
    end)
  end
end

defmodule MonitoringActor do
  def start(monitored_actor) do
    spawn(fn -> monitor_loop(monitored_actor) end)
  end

  def monitor_loop(monitored_actor) do
    Process.monitor(monitored_actor)

    receive do
      {:DOWN, _, _, _, reason} ->
        IO.puts("Monitoring Actor recieved message: stopped with reason '#{reason}'")
    end
  end
end

monitored_pid = MonitoredActor.start()
MonitoringActor.start(monitored_pid)

defmodule AverageActor do
  def start() do
    spawn(fn -> loop() end)
  end

  def loop() do
    receive do
      number ->
        initial_average = number
        IO.puts("Current average is #{initial_average}")
        loop(initial_average)
    end
  end

  def loop(average) do
    receive do
      number ->
        new_average = (average + number) / 2
        IO.puts("Current average is #{new_average}")
        loop(new_average)
    end
  end
end

average_actor = AverageActor.start()
send(average_actor, 0)
send(average_actor, 10)
send(average_actor, 10)
send(average_actor, 10)

defmodule QueueActor do
  def new_queue do
    spawn_link(__MODULE__, :init, [[]])
  end

  def push(pid, item) do
    send(pid, {:push, item})
    :ok
  end

  def pop(pid) do
    send(pid, {:pop, self()})

    receive do
      {:value, item} ->
        item
    end
  end

  def init(queue) do
    receive do
      {:push, item} ->
        if queue do
          new_queue = queue ++ [item]
          init(new_queue)
        end

      {:pop, pid} ->
        if queue == [] do
          init([])
        else
          [item | rest] = queue
          send(pid, {:value, item})
          init(rest)
        end
    end
  end
end

pid = QueueActor.new_queue()
IO.puts(QueueActor.push(pid, 5))
IO.puts(QueueActor.push(pid, 6))
IO.puts(QueueActor.push(pid, 7))
IO.puts(QueueActor.pop(pid))
IO.puts(QueueActor.pop(pid))
IO.puts(QueueActor.pop(pid))

defmodule Semaphore do
  def start(count) do
    spawn_link(fn -> init(count) end)
  end

  defp init(count) do
    receive do
      {:acquire, sender} ->
        # IO.puts(count)
        if count > 0 do
          send(sender, :ok)
          init(count - 1)
        else
          init(count)
        end

      {:release, sender} ->
        # IO.puts(count+1)
        send(sender, :ok)
        init(count + 1)

      :shutdown ->
        :ok
    end
  end

  def acquire(semaphore) do
    send(semaphore, {:acquire, self()})

    receive do
      :ok ->
        :ok
        # IO.puts("Aquired")
    end
  end

  def release(semaphore) do
    send(semaphore, {:release, self()})

    receive do
      :ok ->
        :ok
        # IO.puts("Released")
    end
  end
end

mutex = Semaphore.start(5)
IO.puts(Semaphore.acquire(mutex))
IO.puts(Semaphore.release(mutex))


defmodule Scheduler do
  def start() do
    spawn_link(__MODULE__, :supervise, [])
  end

  def supervise() do
    receive do
      {:completed} ->
        IO.puts("The worker solved its task!")

      {:failed, pid} ->
        IO.puts("Worker failed. Restarting it...")
        Process.exit(pid, :normal)
        RiskyTask.start(self())
    end
    supervise()
  end
end

defmodule RiskyTask do
  def start(scheduler) do
    IO.puts("Starting risky task")
    spawn_link(__MODULE__, :do_task, [scheduler])
  end

  def do_task(scheduler) do
    if :rand.uniform() < 0.5 do
      send(scheduler, {:failed, self()})
    else
      send(scheduler, {:completed})
    end
  end
end

scheduler = Scheduler.start()
RiskyTask.start(scheduler)
