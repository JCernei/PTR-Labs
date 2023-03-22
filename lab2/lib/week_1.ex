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
#     GenServer.cast(Process.whereis(:TweetPrinter), {:tweet, data, self()})
#     GenServer.cast(Process.whereis(:PopularHashtagPrinter), {:tweet, data, self()})
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
#     GenServer.cast(Process.whereis(:TweetPrinter), {:tweet, data, self()})
#     GenServer.cast(Process.whereis(:PopularHashtagPrinter), {:tweet, data, self()})
#     {:noreply, state}
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

# defmodule TweetPrinter do
#   use GenServer
#   require Jason
#   require Statistics
#   require Logger

#   def start_link(lambda \\ []) do
#     GenServer.start_link(__MODULE__, lambda, name: :TweetPrinter)
#   end

#   def init(lambda) do
#     {:ok, lambda}
#   end

#   def handle_cast({:tweet, %EventsourceEx.Message{data: data}, pid}, lambda) do
#     case Jason.decode(data) do
#       {:ok, json_data} ->
#         IO.puts("Tweet from #{get_name(pid)}: #{inspect(json_data["message"]["tweet"]["text"])}")

#         sleep_time = Statistics.Distributions.Poisson.rand(lambda) |> round()
#         IO.inspect(sleep_time)
#         :timer.sleep(sleep_time)

#         {:noreply, lambda}

#       _ ->
#         IO.puts("Error extracting tweet text from JSON data: #{data}")
#         {:noreply, lambda}
#     end
#   end

#   def get_name(pid) do
#     case Process.info(pid, :registered_name) do
#       {:registered_name, name} -> name
#       _ -> nil
#     end
#   end
# end

# defmodule PopularHashtagPrinter do
#   use GenServer
#   require Jason

#   def start_link() do
#     GenServer.start_link(__MODULE__, [], name: :PopularHashtagPrinter)
#   end

#   def init([]) do
#     result_list = []
#     schedule_printing(result_list)
#     {:ok, result_list}
#   end

#   def handle_cast({:tweet, %EventsourceEx.Message{data: data}, pid}, state) do
#     case Jason.decode(data) do
#       {:ok, json_data} ->
#         hashtag_list = json_data["message"]["tweet"]["entities"]["hashtags"]

#         hashtag_text_list =
#           Enum.map(hashtag_list, fn hashtag ->
#             Map.get(hashtag, "text")
#           end)

#         result_list = state ++ hashtag_text_list
#         {:noreply, result_list}

#       _ ->
#         {:noreply, state}
#     end
#   end

#   defp schedule_printing(result_list) do
#     Process.send_after(self(), :print_popular_hashtag, 5000)
#     {:ok, result_list}
#   end

#   defp most_common(list) do
#     frequencies =
#       list
#       |> Enum.frequencies()

#     most_common =
#       frequencies
#       |> Enum.max_by(fn {_string, frequency} -> frequency end)

#     elem(most_common, 0)
#   end

#   def handle_info(:print_popular_hashtag, state) do
#     IO.puts("Most popular hashtag in the last 5 seconds: #{inspect(most_common(state))}")
#     schedule_printing([])
#     {:noreply, []}
#   end
# end

# defmodule MyApp do
#   def run do
#     {:ok, supervisor_pid} = SSEReaderSupervisor.start_link()
#     # TweetPrinter.start_link(5)
#     PopularHashtagPrinter.start_link()

#     IO.gets("")
#     Process.exit(supervisor_pid, :kill)
#   end
# end

# # Start the application and run it until keyboard interrupt
# MyApp.run()
