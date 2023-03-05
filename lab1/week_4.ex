defmodule Worker do
  use GenServer

  def start_link(worker_id) do
    GenServer.start_link(__MODULE__, worker_id)
  end

  def init(worker_id) do
    Process.register(self(), String.to_atom("Worker#{worker_id}"))
    IO.puts("Entered init worker #{inspect(worker_id)} with #{inspect(self())}")
    {:ok, worker_id}
  end

  def handle_cast(:kill, state) do
    IO.puts("Worker #{inspect(self())} received :kill message, stopping")
    Process.exit(self(), :kill)
    {:stop, :kill, state}
  end

  def handle_cast(message, _state) do
    IO.puts("Worker #{inspect(self())} received message: #{inspect(message)}")
    {:noreply, nil}
  end
end

defmodule WorkerSupervisor do
  use Supervisor

  def start_link(worker_count) do
    Supervisor.start_link(__MODULE__, worker_count)
  end

  def init(worker_count) do
    IO.puts("Supervisor entered init")
    Process.register(self(), :WorkerSupervisor)

    children =
      for i <- 1..worker_count do
        worker = {Worker, i}
        Supervisor.child_spec(worker, id: i, restart: :permanent)
      end

    IO.puts("Supervisor starts workers")
    Supervisor.init(children, strategy: :one_for_one)
  end

  def send_message(worker_id, message) do
    worker_pid = Process.whereis(String.to_atom("Worker#{worker_id}"))

    case worker_pid do
      nil ->
        IO.puts("Worker #{worker_id} not found")

      pid ->
        case message do
          :kill ->
            IO.puts("Send :kill message to Worker#{worker_id}")
            GenServer.cast(pid, :kill)
            :timer.sleep(1)

          text ->
            IO.puts("Send message to Worker#{worker_id}")
            GenServer.cast(pid, text)
        end
    end
  end

  def worker_pids do
    supervisor_pid = Process.whereis(:WorkerSupervisor)
    IO.puts("Getting children pids")
    children = Supervisor.which_children(supervisor_pid)
    _child_pids = Enum.map(children, fn {_, pid, _, _} -> pid end)
  end
end

# WorkerSupervisor.start_link(3)
# IO.inspect(WorkerSupervisor.worker_pids())
# WorkerSupervisor.send_message(1, "Hello, worker 1!")
# WorkerSupervisor.send_message(2, "Hello, worker 2!")
# WorkerSupervisor.send_message(3, "Hello, worker 3!")
# WorkerSupervisor.send_message(3, :kill)
# IO.inspect(WorkerSupervisor.worker_pids())
# WorkerSupervisor.send_message(3, "Hello again, worker 3!")

defmodule StringSplitter do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    IO.puts("Started Splitter")
    Process.register(self(), :StringSplitter)
    {:ok, :state}
  end

  def handle_cast(:kill, state) do
    IO.puts(
      "Actor #{inspect(StringCleanerSupervisor.get_name(self()))} received :kill message, stopping"
    )

    Process.exit(self(), :kill)
    {:stop, :kill, state}
  end

  def handle_cast(input_string, state) do
    IO.puts("Entered Splitter handler")

    with string_list when is_list(string_list) <- String.split(input_string, ~r/\s+/) do
      GenServer.cast(Process.whereis(:StringLowercaser), string_list)
      {:noreply, state}
    else
      _ -> {:stop, :invalid_input, "Failed to split the string"}
    end
  end
end

defmodule StringLowercaser do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    IO.puts("Started Lowercaser")
    Process.register(self(), :StringLowercaser)
    {:ok, :state}
  end

  def handle_cast(:kill, state) do
    IO.puts(
      "Actor #{inspect(StringCleanerSupervisor.get_name(self()))} received :kill message, stopping"
    )

    Process.exit(self(), :kill)
    {:stop, :kill, state}
  end

  def handle_cast(string_list, state) do
    IO.puts("Entered Lowercaser handler")

    cleaned_string_list =
      Enum.map(string_list, fn word ->
        word
        |> String.downcase()
        |> String.replace("n", "_")
        |> String.replace("m", "n")
        |> String.replace("_", "m")
      end)

    GenServer.cast(Process.whereis(:StringJoiner), cleaned_string_list)
    {:noreply, state}
  end
end

defmodule StringJoiner do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    IO.puts("Started Joiner")
    Process.register(self(), :StringJoiner)
    {:ok, :state}
  end

  def handle_cast(:kill, state) do
    IO.puts(
      "Actor #{inspect(StringCleanerSupervisor.get_name(self()))} received :kill message, stopping"
    )

    Process.exit(self(), :kill)
    {:stop, :kill, state}
  end

  def handle_cast(cleaned_string_list, state) do
    IO.puts("Entered Joiner handler")

    with cleaned_string when is_binary(cleaned_string) <- Enum.join(cleaned_string_list, " ") do
      IO.puts("RESULT: #{cleaned_string}")
      {:noreply, state}
    else
      _ -> {:stop, :invalid_input, "Failed to join the words"}
    end
  end
end

defmodule StringCleanerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    Process.register(self(), :StringCleanerSupervisor)

    children = [
      %{
        id: StringSplitter,
        start: {StringSplitter, :start_link, []},
        restart: :permanent
      },
      %{
        id: StringLowercaser,
        start: {StringLowercaser, :start_link, []},
        restart: :permanent
      },
      %{
        id: StringJoiner,
        start: {StringJoiner, :start_link, []},
        restart: :permanent
      }
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end

  def send_input(pid, message) do
    case pid do
      nil ->
        IO.puts("Actor not found")

      pid ->
        case message do
          :kill ->
            IO.puts("Send :kill message to Actor#{inspect(get_name(pid))}")
            GenServer.cast(pid, :kill)
            :timer.sleep(1)

          text ->
            IO.puts("Send input to #{inspect(get_name(pid))}")
            GenServer.cast(pid, text)
        end
    end
  end

  def get_name(pid) do
    case Process.info(pid, :registered_name) do
      {:registered_name, name} -> name
      _ -> nil
    end
  end
end

# string_to_clean = "iNput sTrInG tO CLEAn monster"
# IO.puts("String to clean: #{inspect(string_to_clean)}")
# StringCleanerSupervisor.start_link()
# StringCleanerSupervisor.send_input(Process.whereis(:StringSplitter), string_to_clean)
# # StringCleanerSupervisor.send_input(Process.whereis(:StringSplitter), :kill)
# StringCleanerSupervisor.send_input(Process.whereis(:StringJoiner), :kill)
# StringCleanerSupervisor.send_input(Process.whereis(:StringSplitter), string_to_clean)
