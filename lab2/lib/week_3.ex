# defmodule TweetPrinterPool do
#   use Supervisor
#   import ProcessHelper

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

#   def get_num_workers do
#     supervisor = Process.whereis(:TweetPrinterPool)
#     children = Supervisor.which_children(supervisor)
#     num_workers = length(children)
#     {:ok, num_workers}
#   end

#   def add_worker(lambda) do
#     IO.puts("\nAdding new worker\n")
#     supervisor = Process.whereis(:TweetPrinterPool)
#     children = Supervisor.which_children(supervisor)
#     worker = {TweetPrinter, [length(children) + 1, lambda]}
#     new_child = Supervisor.child_spec(worker, id: length(children) + 1, restart: :temporary)
#     Supervisor.start_child(supervisor, new_child)
#     # GenServer.cast(:TweetMediator, {:update_pool_size, length(children) + 1})
#   end

#   def remove_worker do
#     IO.puts("\nRemoving worker\n")
#     supervisor = Process.whereis(:TweetPrinterPool)
#     children = Supervisor.which_children(supervisor)
#     children_ids = Enum.map(children, fn {id, _, _, _} -> id end)
#     child_id_to_remove = Enum.max(children_ids)
#     Supervisor.terminate_child(supervisor, child_id_to_remove)
#     Supervisor.delete_child(supervisor, child_id_to_remove)
#     # GenServer.cast(:TweetMediator, {:update_pool_size, length(children) - 1})
#   end
# end

# defmodule WorkerManager do
#   use GenServer
#   import ProcessHelper

#   def start_link([min_workers, lambda] \\ []) do
#     GenServer.start_link(__MODULE__, [min_workers, lambda], name: :WorkerManager)
#   end

#   def init([min_workers, lambda]) do
#     # IO.puts("Managing the pool")
#     {:ok, num_workers} = TweetPrinterPool.get_num_workers()
#     IO.puts("\nPool size is #{inspect(num_workers)}\n")

#     case get_child_queue_len(num_workers) do
#       {:ok, queue_len} ->
#         # {:ok, queue_len} = get_child_queue_len(num_workers)
#         # if num_workers == 3 do
#         #   :timer.sleep(100)
#         # end

#         if queue_len > 100 do
#           # IO.puts("Adding new worker")
#           TweetPrinterPool.add_worker(lambda)
#         end

#         if queue_len < 100 && num_workers > min_workers do
#           TweetPrinterPool.remove_worker()
#         end

#         :timer.sleep(100)

#       {:error, :process_not_found} ->
#         :timer.sleep(100)
#     end

#     init([min_workers, lambda])
#     {:noreply, lambda}
#   end

#   def get_child_queue_len(num_workers) do
#     pids = for i <- 1..num_workers, do: Process.whereis(:"TweetPrinter#{i}")

#     if Enum.all?(pids, &is_pid/1) do
#       queue_len =
#         Enum.reduce(pids, 0, fn pid, acc ->
#           info = Process.info(pid, [:message_queue_len])
#           acc + info[:message_queue_len]
#         end)

#       IO.puts("\nQueue length is #{queue_len}\n")
#       {:ok, queue_len}
#     else
#       IO.puts("Error: One or more child processes not found")
#       {:error, :process_not_found}
#     end
#   end
# end

# defmodule TweetMediator do
#   use GenServer
#   import ProcessHelper

#   def start_link(lambda \\ []) do
#     GenServer.start_link(__MODULE__, lambda, name: :TweetMediator)
#   end

#   def init(lambda) do
#     {:ok, pool} = TweetPrinterPool.start_link(lambda)

#     {:ok, pool_size} = TweetPrinterPool.get_num_workers()
#     {:ok, %{pool_size: pool_size, pool: pool, counter: 0}}
#   end

#   def handle_cast({:tweet, data, _pid}, state) do
#     case get_worker_id(state) do
#       {worker_id, new_counter} ->
#         worker_pid = Process.whereis(String.to_atom("TweetPrinter#{worker_id}"))
#         GenServer.cast(worker_pid, {:tweet, data, self()})
#         {:noreply, %{state | counter: new_counter}}

#       _ ->
#         {:noreply, state}
#     end

#     # {worker_id, new_counter} = get_worker_id(state)
#     # # IO.inspect(worker_id)
#     # worker_pid = Process.whereis(String.to_atom("TweetPrinter#{worker_id}"))
#     # GenServer.cast(worker_pid, {:tweet, data, self()})
#     # {:noreply, %{state | counter: new_counter}}
#   end

#   def handle_cast(nil, state) do
#     {:noreply, state}
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
#     %{counter: counter, pool: _pool, pool_size: _pool_size} = state
#     {:ok, pool_size} = TweetPrinterPool.get_num_workers()
#     first_worker = :rand.uniform(pool_size)

#     second_worker =
#       case :rand.uniform(pool_size - 1) do
#         n when n < first_worker -> n
#         n -> n + 1
#       end

#     # case Process.alive?(ProcessHelper.get_worker_pid(first_worker)) &&
#     #        Process.alive?(ProcessHelper.get_worker_pid(second_worker)) do
#     #   :error ->
#     #     get_worker_id(state)

#     try do
#       info_first_worker =
#         Process.info(ProcessHelper.get_worker_pid(first_worker), [:message_queue_len])

#       tasks_first = info_first_worker[:message_queue_len]

#       info_second_worker =
#         Process.info(ProcessHelper.get_worker_pid(second_worker), [:message_queue_len])

#       tasks_second = info_second_worker[:message_queue_len]

#       IO.puts(
#         "Comparing #{ProcessHelper.get_name(ProcessHelper.get_worker_pid(first_worker))} - #{inspect(tasks_first)} with #{ProcessHelper.get_name(ProcessHelper.get_worker_pid(second_worker))} - #{inspect(tasks_second)}"
#       )

#       worker_id =
#         if tasks_first <= tasks_second do
#           IO.puts(
#             "#{ProcessHelper.get_name(ProcessHelper.get_worker_pid(first_worker))} recieved data"
#           )

#           first_worker
#         else
#           IO.puts(
#             "#{ProcessHelper.get_name(ProcessHelper.get_worker_pid(second_worker))} recieved data"
#           )

#           second_worker
#         end

#       new_counter = if counter == pool_size - 1, do: 0, else: counter + 1
#       {worker_id, new_counter}
#     catch
#       error ->
#         get_worker_id(state)
#     end
#   end
# end

# defmodule TweetPrinter do
#   use GenServer
#   require Jason
#   require Statistics
#   import ProcessHelper

#   @bad_words File.read!("lib/bad-words.txt") |> String.split("\r\n")

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
#         tweet_text = json_data["message"]["tweet"]["text"]
#         filtered_tweet_text = filter_bad_words(tweet_text)

#         IO.puts(
#           "From #{ProcessHelper.get_name(pid)} by #{ProcessHelper.get_name(self())} censored: #{inspect(filtered_tweet_text)}"
#         )

#         IO.puts(
#           "From #{ProcessHelper.get_name(pid)} by #{ProcessHelper.get_name(self())} uncensored: #{inspect(tweet_text)}"
#         )

#         sleep_time = Statistics.Distributions.Poisson.rand(lambda) |> round()
#         # IO.inspect(sleep_time)
#         :timer.sleep(sleep_time)

#         {:noreply, lambda}

#       _ ->
#         IO.puts("Error extracting tweet text from JSON data: #{data}")
#         IO.puts("#{ProcessHelper.get_name(self())} DIED")
#         # Process.exit(self(), :kill)
#         {:noreply, lambda}
#     end
#   end

#   defp filter_bad_words(tweet_text) do
#     String.split(tweet_text, " ")
#     |> Enum.map(fn word ->
#       original_word = word
#       # remove special characters
#       word = String.replace(word, ~r/[^a-zA-Z0-9]/, " ")

#       if Enum.member?(@bad_words, String.downcase(word)) do
#         IO.puts("bad word: #{inspect(word)}")
#         String.duplicate("*", String.length(word))
#       else
#         original_word
#       end
#     end)
#     |> Enum.join(" ")
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
#     lambda = 50
#     min_workers = 10
#     {:ok, reader_supervisor_pid} = SSEReaderSupervisor.start_link()
#     {:ok, printer_mediator_pid} = TweetMediator.start_link(lambda)
#     WorkerManager.start_link([min_workers, lambda])

#     :timer.sleep(2000)
#     Process.exit(reader_supervisor_pid, :kill)
#     Process.exit(printer_mediator_pid, :kill)
#   end
# end

# # Start the application and run it until keyboard interrupt
# MyApp.run()
