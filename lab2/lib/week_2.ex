# defmodule TweetPrinterPool do
#   use Supervisor

#   def start_link(lambda) do
#     Supervisor.start_link(__MODULE__, lambda, name: :TweetPrinterPool)
#   end

#   def init(lambda) do
#     children =
#       for i <- 1..3 do
#         worker = {TweetPrinter, [i, lambda]}
#         Supervisor.child_spec(worker, id: i, restart: :permanent)
#       end

#     Supervisor.init(children, strategy: :one_for_one)
#   end
# end

# defmodule TweetMediator do
#   use GenServer
#   import ProcessHelper

#   def start_link(lambda \\ []) do
#     GenServer.start_link(__MODULE__, lambda, name: :TweetMediator)
#   end

#   def init(lambda) do
#     Process.send_after(self(), :print_queue_lengths, 1000)
#     {:ok, %{pool_size: 3, pool: TweetPrinterPool.start_link(lambda), counter: 0}}
#   end

#   def handle_cast({:tweet, data, _pid}, state) do
#     {worker_id, new_counter} = get_worker_id(state)
#     # IO.inspect(worker_id)
#     worker_pid = Process.whereis(String.to_atom("TweetPrinter#{worker_id}"))
#     GenServer.cast(worker_pid, {:tweet, data, self()})
#     {:noreply, %{state | counter: new_counter}}
#   end

#   # # Round Robin
#   # defp get_worker_id(state) do
#   #   %{counter: counter, pool: _pool, pool_size: pool_size} = state
#   #   worker_id = counter + 1
#   #   new_counter = if counter == pool_size - 1, do: 0, else: counter + 1
#   #   {worker_id, new_counter}
#   # end

#   # The Power of Two Choices
#   defp get_worker_id(state) do
#     %{counter: counter, pool: _pool, pool_size: pool_size} = state
#     first_worker = :rand.uniform(pool_size)

#     second_worker =
#       case :rand.uniform(pool_size - 1) do
#         n when n < first_worker -> n
#         n -> n + 1
#       end

#     info_first_worker = Process.info(get_worker_pid(first_worker), [:message_queue_len])
#     tasks_first = info_first_worker[:message_queue_len]
#     info_second_worker = Process.info(get_worker_pid(second_worker), [:message_queue_len])
#     tasks_second = info_second_worker[:message_queue_len]

#     IO.puts(
#       "Comparing #{ProcessHelper.get_name(get_worker_pid(first_worker))} - #{inspect(tasks_first)} with #{ProcessHelper.get_name(get_worker_pid(second_worker))} - #{inspect(tasks_second)}"
#     )

#     worker_id =
#       if tasks_first <= tasks_second do
#         IO.puts("#{ProcessHelper.get_name(get_worker_pid(first_worker))} recieved data")
#         first_worker
#       else
#         IO.puts("#{ProcessHelper.get_name(get_worker_pid(second_worker))} recieved data")
#         second_worker
#       end

#     new_counter = if counter == pool_size - 1, do: 0, else: counter + 1
#     {worker_id, new_counter}
#   end

#   def handle_info(:print_queue_lengths, state) do
#     Process.send_after(self(), :print_queue_lengths, 1000)

#     info_mediator = Process.info(Process.whereis(:TweetMediator), [:message_queue_len])
#     info_first_worker = Process.info(Process.whereis(:TweetPrinter1), [:message_queue_len])
#     info_second_worker = Process.info(Process.whereis(:TweetPrinter2), [:message_queue_len])
#     info_third_worker = Process.info(Process.whereis(:TweetPrinter3), [:message_queue_len])

#     IO.puts("TweetMediator has #{inspect(info_mediator[:message_queue_len])}")
#     IO.puts("TweetPrinter1 has #{inspect(info_first_worker[:message_queue_len])}")
#     IO.puts("TweetPrinter2 has #{inspect(info_second_worker[:message_queue_len])}")
#     IO.puts("TweetPrinter3 has #{inspect(info_third_worker[:message_queue_len])}")

#     {:noreply, state}
#   end

#   defp get_worker_pid(worker_id) do
#     Process.whereis(String.to_atom("TweetPrinter#{worker_id}"))
#   end
# end

# defmodule TweetPrinter do
#   use GenServer
#   require Jason
#   require Statistics
#   require Logger
#   import ProcessHelper

#   def start_link([id, lambda] \\ []) do
#     GenServer.start_link(__MODULE__, [id, lambda])
#   end

#   def init([id, lambda]) do
#     IO.puts("Starting TweetPrinter#{id}")
#     Process.register(self(), String.to_atom("TweetPrinter#{id}"))
#     {:ok, lambda}
#   end

#   def handle_cast({:tweet, %EventsourceEx.Message{data: data}, pid}, lambda) do
#     case Jason.decode(data) do
#       {:ok, json_data} ->
#         IO.puts(
#           "From #{ProcessHelper.get_name(pid)} by #{ProcessHelper.get_name(self())}: #{inspect(json_data["message"]["tweet"]["text"])}"
#         )

#         sleep_time = Statistics.Distributions.Poisson.rand(lambda) |> round()
#         IO.inspect(sleep_time)
#         :timer.sleep(sleep_time)

#         {:noreply, lambda}

#       _ ->
#         IO.puts("Error extracting tweet text from JSON data: #{data}")
#         IO.puts("#{ProcessHelper.get_name(self())} DIED")
#         Process.exit(self(), :kill)
#         {:noreply, lambda}
#     end
#   end
# end

# defmodule SSEReaderSupervisor do
#   use Supervisor

#   def start_link do
#     Supervisor.start_link(__MODULE__, [])
#   end

#   def init(_) do
#     Process.register(self(), :SSEReaderSupervisor)

#     children = [
#       %{
#         id: SSEReader,
#         start: {SSEReader, :start_link, ["http://localhost:4000/tweets/1"]},
#         restart: :permanent
#       },
#       %{
#         id: SSEReader2,
#         start: {SSEReader2, :start_link, ["http://localhost:4000/tweets/2"]},
#         restart: :permanent
#       }
#     ]

#     Supervisor.init(children, strategy: :one_for_one)
#   end
# end

# defmodule SSEReader do
#   use GenServer
#   require EventsourceEx
#   require Logger

#   :application.ensure_all_started(:hackney)

#   def start_link(url \\ []) do
#     GenServer.start_link(__MODULE__, url, name: :SSEReader)
#   end

#   def init(url) do
#     EventsourceEx.new(url, stream_to: self())
#     {:ok, url}
#   end

#   def handle_info(data, state) do
#     GenServer.cast(Process.whereis(:TweetMediator), {:tweet, data, self()})
#     {:noreply, state}
#   end
# end

# defmodule SSEReader2 do
#   use GenServer
#   require EventsourceEx
#   require Logger

#   :application.ensure_all_started(:hackney)

#   def start_link(url \\ []) do
#     GenServer.start_link(__MODULE__, url, name: :SSEReader2)
#   end

#   def init(url) do
#     EventsourceEx.new(url, stream_to: self())
#     {:ok, url}
#   end

#   def handle_info(data, state) do
#     GenServer.cast(Process.whereis(:TweetMediator), {:tweet, data, self()})
#     {:noreply, state}
#   end
# end

# defmodule MyApp do
#   def run do
#     {:ok, reader_supervisor_pid} = SSEReaderSupervisor.start_link()
#     {:ok, printer_mediator_pid} = TweetMediator.start_link(50)

#     :timer.sleep(5000)
#     Process.exit(reader_supervisor_pid, :kill)
#     Process.exit(printer_mediator_pid, :kill)
#   end
# end

# # Start the application and run it until keyboard interrupt
# MyApp.run()
