# defmodule TweetPrinterPool do
#   use Supervisor

#   def start_link([worker_type, lambda, min_workers]) do
#     Supervisor.start_link(__MODULE__, [worker_type, lambda, min_workers])
#   end

#   def init([worker_type, lambda, min_workers]) do
#     worker_name = Module.split(worker_type) |> List.last()
#     IO.puts("Starting #{worker_name}Pool")
#     Process.register(self(), String.to_atom("#{worker_type}Pool"))

#     children =
#       for i <- 1..min_workers do
#         worker = {worker_type, [i, lambda]}
#         Supervisor.child_spec(worker, id: i, restart: :permanent)
#       end

#     Supervisor.init(children, strategy: :one_for_one)
#   end

#   def get_num_workers(pool_type) do
#     supervisor_name =
#       case pool_type do
#         :redactor -> TweetRedactorPool
#         :sentiment -> SentimentScoreCalculatorPool
#         :engagement -> EngagementRatioCalculatorPool
#       end

#     supervisor = Process.whereis(supervisor_name)
#     children = Supervisor.which_children(supervisor)
#     num_workers = length(children)
#     {:ok, num_workers}
#   end
# end

# defmodule TweetMediator do
#   use GenServer
#   require UUID

#   def start_link([lambda, min_workers]) do
#     GenServer.start_link(__MODULE__, [lambda, min_workers], name: :TweetMediator)
#   end

#   def init([lambda, min_workers]) do
#     IO.puts("Starting the mediator")
#     {:ok, redactor_pool} = TweetPrinterPool.start_link([TweetRedactor, lambda, min_workers])

#     {:ok, sentiment_calculator_pool} =
#       TweetPrinterPool.start_link([SentimentScoreCalculator, lambda, min_workers])

#     {:ok, engagement_ratio_pool} =
#       TweetPrinterPool.start_link([EngagementRatioCalculator, lambda, min_workers])

#     {:ok,
#      %{
#        redactor_pool: redactor_pool,
#        sentiment_calculator_pool: sentiment_calculator_pool,
#        engagement_ratio_pool: engagement_ratio_pool
#      }}
#   end

#   def handle_cast({:tweet, data}, state) do
#     {redactor_pid, sentiment_calculator_pid, engagement_ratio_pid} = choose_worker_pid()
#     message_id = UUID.uuid1()

#     GenServer.cast(redactor_pid, {:tweet, data, id: message_id})
#     GenServer.cast(sentiment_calculator_pid, {:tweet, data, id: message_id})
#     GenServer.cast(engagement_ratio_pid, {:tweet, data, id: message_id})
#     {:noreply, state}
#   end

#   # Least Connected
#   defp choose_worker_pid() do
#     {:ok, redactor_pool_size} = TweetPrinterPool.get_num_workers(:redactor)
#     {:ok, sentiment_pool_size} = TweetPrinterPool.get_num_workers(:sentiment)
#     {:ok, engagement_pool_size} = TweetPrinterPool.get_num_workers(:engagement)

#     redactor_task_counts =
#       for i <- 1..redactor_pool_size do
#         redactor_worker_pid = ProcessHelper.get_worker_pid(TweetRedactor, i)

#         case redactor_worker_pid do
#           nil ->
#             {:skip, i}

#           pid ->
#             info = Process.info(pid, [:message_queue_len])
#             {pid, info[:message_queue_len]}
#         end
#       end

#     sentiment_task_counts =
#       for i <- 1..sentiment_pool_size do
#         sentiment_worker_pid = ProcessHelper.get_worker_pid(SentimentScoreCalculator, i)

#         case sentiment_worker_pid do
#           nil ->
#             {:skip, i}

#           pid ->
#             info = Process.info(pid, [:message_queue_len])
#             {pid, info[:message_queue_len]}
#         end
#       end

#     engagement_task_counts =
#       for i <- 1..engagement_pool_size do
#         engagement_worker_pid = ProcessHelper.get_worker_pid(EngagementRatioCalculator, i)

#         case engagement_worker_pid do
#           nil ->
#             {:skip, i}

#           pid ->
#             info = Process.info(pid, [:message_queue_len])
#             {pid, info[:message_queue_len]}
#         end
#       end

#     sorted_redactor_workers = Enum.sort_by(redactor_task_counts, fn {_pid, count} -> count end)
#     {redactor_pid, _} = hd(sorted_redactor_workers)

#     sorted_sentiment_workers = Enum.sort_by(sentiment_task_counts, fn {_pid, count} -> count end)
#     {sentiment_calculator_pid, _} = hd(sorted_sentiment_workers)

#     sorted_engagement_workers =
#       Enum.sort_by(engagement_task_counts, fn {_pid, count} -> count end)

#     {engagement_ratio_pid, _} = hd(sorted_engagement_workers)

#     {redactor_pid, sentiment_calculator_pid, engagement_ratio_pid}
#   end
# end

# defmodule TweetRedactor do
#   use GenServer

#   @bad_words File.read!("lib/bad-words.txt") |> String.split("\r\n")

#   def start_link([id, lambda]) do
#     GenServer.start_link(__MODULE__, [id, lambda])
#   end

#   def init([id, lambda]) do
#     IO.puts("Starting TweetRedactor#{id}")
#     Process.register(self(), String.to_atom("TweetRedactor#{id}"))
#     {:ok, lambda}
#   end

#   def handle_cast({:tweet, %EventsourceEx.Message{data: data}, id: message_id}, lambda) do
#     case Jason.decode(data) do
#       {:ok, json_data} ->
#         tweet_text = json_data["message"]["tweet"]["text"]
#         retweeted = json_data["message"]["tweet"]["retweeted"]

#         redacted_text = redact(tweet_text)
#         # IO.puts("Redacted text by #{ProcessHelper.get_name(self())}: #{inspect(redacted_text)}")
#         if retweeted == false do
#           GenServer.cast(
#             Process.whereis(:Aggregator),
#             {:redacted_text, redacted_text, :id, message_id}
#           )
#         else
#           GenServer.cast(
#             Process.whereis(:RetweetAggregator),
#             {:redacted_text, redacted_text, :id, message_id}
#           )
#         end

#         sleep_time = Statistics.Distributions.Poisson.rand(lambda) |> round()
#         :timer.sleep(sleep_time)
#         {:noreply, lambda}

#       _ ->
#         IO.puts("Error extracting tweet text from JSON data: #{data}")
#         IO.puts("#{ProcessHelper.get_name(self())} DIED")
#         Process.exit(self(), :kill)
#         {:noreply, lambda}
#     end
#   end

#   defp redact(text) do
#     String.split(text, " ")
#     |> Enum.map(fn word ->
#       original_word = word

#       if Enum.member?(@bad_words, String.downcase(word)) do
#         # IO.puts("bad word: #{inspect(word)}")
#         String.duplicate("*", String.length(word))
#       else
#         original_word
#       end
#     end)
#     |> Enum.join(" ")
#   end
# end

# defmodule SentimentScoreCalculator do
#   use GenServer
#   require HTTPoison

#   def start_link([id, lambda]) do
#     GenServer.start_link(__MODULE__, [id, lambda])
#   end

#   def init([id, lambda]) do
#     IO.puts("Starting SentimentScoreCalculator#{id}")
#     Process.register(self(), String.to_atom("SentimentScoreCalculator#{id}"))
#     {:ok, lambda}
#   end

#   def handle_cast({:tweet, %EventsourceEx.Message{data: data}, id: message_id}, lambda) do
#     case Jason.decode(data) do
#       {:ok, json_data} ->
#         tweet_text = json_data["message"]["tweet"]["text"]
#         retweeted = json_data["message"]["tweet"]["retweeted"]

#         emotional_scores = get_sentiment_map()
#         sentiment_score = calculate_sentiment(tweet_text, emotional_scores)

#         # IO.puts(
#         #   "The sentiment score by #{ProcessHelper.get_name(self())} is: #{inspect(sentiment_score)}"
#         # )
#         if retweeted == false do
#           GenServer.cast(
#             Process.whereis(:Aggregator),
#             {:sentiment_score, sentiment_score, :id, message_id}
#           )
#         else
#           GenServer.cast(
#             Process.whereis(:RetweetAggregator),
#             {:sentiment_score, sentiment_score, :id, message_id}
#           )
#         end

#         sleep_time = Statistics.Distributions.Poisson.rand(lambda) |> round()
#         :timer.sleep(sleep_time)
#         {:noreply, lambda}

#       _ ->
#         IO.puts("Error extracting tweet text from JSON data: #{data}")
#         IO.puts("#{ProcessHelper.get_name(self())} DIED")
#         Process.exit(self(), :kill)
#         {:noreply, lambda}
#     end
#   end

#   defp get_sentiment_map() do
#     {:ok, response} = HTTPoison.get("http://localhost:4000/emotion_values")
#     response_body = response.body
#     lines = String.split(response_body, "\r\n")

#     emotional_scores =
#       lines
#       |> Enum.map(&String.split(&1, "\t"))
#       |> Enum.reduce(%{}, fn [word, score], acc ->
#         Map.merge(acc, %{word => String.to_integer(score)})
#       end)

#     emotional_scores
#   end

#   defp calculate_sentiment(text, emotional_scores) do
#     words = String.split(text, " ")
#     scores = words |> Enum.map(&Map.get(emotional_scores, String.downcase(&1), 0))

#     sentiment_score =
#       if Enum.count(scores) > 0, do: Enum.sum(scores) / Enum.count(scores), else: 0

#     sentiment_score
#   end
# end

# defmodule EngagementRatioCalculator do
#   use GenServer

#   def start_link([id, lambda]) do
#     GenServer.start_link(__MODULE__, [id, lambda])
#   end

#   def init([id, lambda]) do
#     IO.puts("Starting EngagementRatioCalculator#{id}")
#     Process.register(self(), String.to_atom("EngagementRatioCalculator#{id}"))
#     {:ok, {lambda, id}}
#   end

#   def handle_cast({:tweet, %EventsourceEx.Message{data: data}, id: message_id}, {lambda, id}) do
#     case Jason.decode(data) do
#       {:ok, json_data} ->
#         # user_id = json_data["message"]["tweet"]["user"]["id_str"]
#         favorite_count = json_data["message"]["tweet"]["favorite_count"]
#         retweeted = json_data["message"]["tweet"]["retweeted"]
#         retweet_count = json_data["message"]["tweet"]["retweet_count"]
#         followers_count = json_data["message"]["tweet"]["user"]["followers_count"]

#         engagement_ratio =
#           compute_ratio(
#             favorite_count,
#             retweet_count,
#             followers_count
#           )

#         # IO.puts(
#         #   "#{inspect(favorite_count)}, #{inspect(retweet_count)}, #{inspect(followers_count)}, Engagement ratio by #{ProcessHelper.get_name(self())} for user #{user_id} is: #{inspect(engagement_ratio)}"
#         # )
#         if retweeted == false do
#           GenServer.cast(
#             Process.whereis(:Aggregator),
#             {:engagement_ratio, engagement_ratio, :id, message_id}
#           )
#         else
#           GenServer.cast(
#             Process.whereis(:RetweetAggregator),
#             {:engagement_ratio, engagement_ratio, :id, message_id}
#           )
#         end

#         sleep_time = Statistics.Distributions.Poisson.rand(lambda) |> round()
#         :timer.sleep(sleep_time)
#         {:noreply, {lambda, id}}

#       _ ->
#         IO.puts("Error extracting tweet text from JSON data: #{data}")
#         IO.puts("#{ProcessHelper.get_name(self())} DIED")
#         Process.exit(self(), :kill)
#         {:noreply, {lambda, id}}
#     end
#   end

#   defp compute_ratio(likes, retweets, followers) do
#     engagement_ratio = if followers > 0, do: (likes + retweets) / followers, else: 0
#     engagement_ratio
#   end
# end

# defmodule Aggregator do
#   use GenServer

#   def start_link do
#     GenServer.start_link(
#       __MODULE__,
#       %{
#         sentiment_scores: %{},
#         redacted_tweets: %{},
#         engagement_ratios: %{}
#       },
#       name: :Aggregator
#     )
#   end

#   def init(state) do
#     IO.puts("Agregator started")
#     schedule_check_aggregate()
#     {:ok, state}
#   end

#   defp schedule_check_aggregate do
#     Process.send_after(self(), :check_aggregate, 100)
#     :noreply
#   end

#   def handle_cast({:redacted_text, redacted_text, :id, message_id}, state) do
#     # IO.puts("Agregator received redacted")
#     redacted_tweets = Map.get(state.redacted_tweets, message_id, [])
#     new_redacted_tweets = [redacted_text | redacted_tweets]

#     {:noreply,
#      Map.put(
#        state,
#        :redacted_tweets,
#        Map.put(state.redacted_tweets, message_id, new_redacted_tweets)
#      )}
#   end

#   def handle_cast({:sentiment_score, sentiment_score, :id, message_id}, state) do
#     # IO.puts("Agregator received sentiment")
#     sentiment_scores = Map.get(state.sentiment_scores, message_id, [])
#     new_sentiment_scores = [sentiment_score | sentiment_scores]

#     {:noreply,
#      Map.put(
#        state,
#        :sentiment_scores,
#        Map.put(state.sentiment_scores, message_id, new_sentiment_scores)
#      )}
#   end

#   def handle_cast({:engagement_ratio, engagement_ratio, :id, message_id}, state) do
#     # IO.puts("Agregator received engagement")
#     engagement_ratios = Map.get(state.engagement_ratios, message_id, [])
#     new_engagement_ratios = [engagement_ratio | engagement_ratios]

#     {:noreply,
#      Map.put(
#        state,
#        :engagement_ratios,
#        Map.put(state.engagement_ratios, message_id, new_engagement_ratios)
#      )}
#   end

#   def handle_info(:check_aggregate, state) do
#     case find_matching_set(state) do
#       nil ->
#         IO.puts("No match found")
#         schedule_check_aggregate()
#         {:noreply, state}

#       matching_sets ->
#         Enum.each(matching_sets, fn matching_set ->
#           # IO.puts("#{inspect({:batch, matching_set})}")
#           GenServer.cast(Process.whereis(:TweetBatcher), {:batch, matching_set})
#           clear_matching_set(state, matching_set)
#         end)

#         schedule_check_aggregate()
#         {:noreply, state}
#     end
#   end

#   defp find_matching_set(state) do
#     redacted_tweets = state.redacted_tweets
#     sentiment_scores = state.sentiment_scores
#     engagement_ratios = state.engagement_ratios

#     maps = [redacted_tweets, sentiment_scores, engagement_ratios]

#     common_keys =
#       Enum.reduce(maps, MapSet.new(Map.keys(redacted_tweets)), fn map, acc ->
#         MapSet.intersection(acc, MapSet.new(Map.keys(map)))
#       end)

#     if MapSet.size(common_keys) > 0 do
#       Enum.reduce(common_keys, [], fn key, matching_sets ->
#         case {Map.fetch(redacted_tweets, key), Map.fetch(sentiment_scores, key),
#               Map.fetch(engagement_ratios, key)} do
#           {{:ok, redacted_tweet}, {:ok, sentiment_score}, {:ok, engagement_ratio}} ->
#             matching_set = [key, redacted_tweet, sentiment_score, engagement_ratio]
#             [matching_set | matching_sets]

#           _ ->
#             matching_sets
#         end
#       end)
#     else
#       nil
#     end
#   end

#   defp clear_matching_set(state, matching_set) do
#     [message_id, _, _, _] = matching_set

#     %{
#       state
#       | redacted_tweets: Map.delete(state.redacted_tweets, message_id),
#         sentiment_scores: Map.delete(state.sentiment_scores, message_id),
#         engagement_ratios: Map.delete(state.engagement_ratios, message_id)
#     }

#     {:noreply, state}
#   end
# end

# defmodule TweetBatcher do
#   use GenServer

#   def start_link(batch_size, time_window) do
#     GenServer.start_link(__MODULE__, {batch_size, time_window}, name: :TweetBatcher)
#   end

#   def init({batch_size, time_window}) do
#     IO.puts("Starting the Batcher")
#     time_ref = print_after(time_window)

#     state = %{
#       matching_sets: [],
#       batch_size: batch_size,
#       time_window: time_window,
#       time_ref: time_ref
#     }

#     {:ok, state}
#   end

#   defp print_after(time_window) do
#     Process.send_after(:TweetBatcher, :timeout, time_window)
#   end

#   def handle_cast({:batch, matching_set}, state) do
#     new_matching_sets = [matching_set | state.matching_sets]

#     if length(new_matching_sets) == state.batch_size do
#       Process.cancel_timer(state.time_ref)
#       IO.puts("\nBatch of #{state.batch_size} tweets:")

#       Enum.with_index(new_matching_sets)
#       |> Enum.each(fn {matching_set, index} ->
#         IO.puts("#{index + 1}. #{inspect(matching_set)}")
#       end)

#       new_time_ref = print_after(state.time_window)
#       {:noreply, %{state | matching_sets: [], time_ref: new_time_ref}}
#     else
#       {:noreply, %{state | matching_sets: new_matching_sets}}
#     end
#   end

#   def handle_info(:timeout, state) do
#     if length(state.matching_sets) > 0 do
#       IO.puts("\nThe time has come")
#       IO.puts("Batch of #{length(state.matching_sets)} tweets (due to time out):")

#       Enum.with_index(state.matching_sets)
#       |> Enum.each(fn {matching_set, index} ->
#         IO.puts("#{index + 1}. #{inspect(matching_set)}")
#       end)

#       new_time_ref = print_after(state.time_window)
#       {:noreply, %{state | matching_sets: [], time_ref: new_time_ref}}
#     else
#       new_time_ref = print_after(state.time_window)
#       {:noreply, %{state | time_ref: new_time_ref}}
#     end
#   end
# end

# defmodule RetweetAggregator do
#   use GenServer

#   def start_link do
#     GenServer.start_link(
#       __MODULE__,
#       %{
#         sentiment_scores: %{},
#         redacted_tweets: %{},
#         engagement_ratios: %{}
#       },
#       name: :RetweeAggregator
#     )
#   end

#   def init(state) do
#     IO.puts("Retweet Agregator started")
#     schedule_check_aggregate()
#     {:ok, state}
#   end

#   defp schedule_check_aggregate do
#     Process.send_after(self(), :check_aggregate, 100)
#     # :noreply
#   end

#   def handle_cast({:redacted_text, redacted_text, :id, message_id}, state) do
#     # IO.puts("Agregator received redacted")
#     redacted_tweets = Map.get(state.redacted_tweets, message_id, [])
#     new_redacted_tweets = [redacted_text | redacted_tweets]

#     {:noreply,
#      Map.put(
#        state,
#        :redacted_tweets,
#        Map.put(state.redacted_tweets, message_id, new_redacted_tweets)
#      )}
#   end

#   def handle_cast({:sentiment_score, sentiment_score, :id, message_id}, state) do
#     # IO.puts("Agregator received sentiment")
#     sentiment_scores = Map.get(state.sentiment_scores, message_id, [])
#     new_sentiment_scores = [sentiment_score | sentiment_scores]

#     {:noreply,
#      Map.put(
#        state,
#        :sentiment_scores,
#        Map.put(state.sentiment_scores, message_id, new_sentiment_scores)
#      )}
#   end

#   def handle_cast({:engagement_ratio, engagement_ratio, :id, message_id}, state) do
#     # IO.puts("Agregator received engagement")
#     engagement_ratios = Map.get(state.engagement_ratios, message_id, [])
#     new_engagement_ratios = [engagement_ratio | engagement_ratios]

#     {:noreply,
#      Map.put(
#        state,
#        :engagement_ratios,
#        Map.put(state.engagement_ratios, message_id, new_engagement_ratios)
#      )}
#   end

#   def handle_info(:check_aggregate, state) do
#     case find_matching_set(state) do
#       nil ->
#         IO.puts("No match found")
#         schedule_check_aggregate()
#         {:noreply, state}

#       matching_sets ->
#         Enum.each(matching_sets, fn matching_set ->
#           IO.puts("\nRetweets #{inspect({:batch, matching_set})}")
#           # GenServer.cast(Process.whereis(:TweetBatcher), {:batch, matching_set})
#           clear_matching_set(state, matching_set)
#         end)

#         schedule_check_aggregate()
#         {:noreply, state}
#     end
#   end

#   defp find_matching_set(state) do
#     redacted_tweets = state.redacted_tweets
#     sentiment_scores = state.sentiment_scores
#     engagement_ratios = state.engagement_ratios

#     maps = [redacted_tweets, sentiment_scores, engagement_ratios]

#     common_keys =
#       Enum.reduce(maps, MapSet.new(Map.keys(redacted_tweets)), fn map, acc ->
#         MapSet.intersection(acc, MapSet.new(Map.keys(map)))
#       end)

#     if MapSet.size(common_keys) > 0 do
#       Enum.reduce(common_keys, [], fn key, matching_sets ->
#         case {Map.fetch(redacted_tweets, key), Map.fetch(sentiment_scores, key),
#               Map.fetch(engagement_ratios, key)} do
#           {{:ok, redacted_tweet}, {:ok, sentiment_score}, {:ok, engagement_ratio}} ->
#             matching_set = [key, redacted_tweet, sentiment_score, engagement_ratio]
#             [matching_set | matching_sets]

#           _ ->
#             matching_sets
#         end
#       end)
#     else
#       nil
#     end
#   end

#   defp clear_matching_set(state, matching_set) do
#     [message_id, _, _, _] = matching_set

#     %{
#       state
#       | redacted_tweets: Map.delete(state.redacted_tweets, message_id),
#         sentiment_scores: Map.delete(state.sentiment_scores, message_id),
#         engagement_ratios: Map.delete(state.engagement_ratios, message_id)
#     }

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
#     GenServer.cast(Process.whereis(:TweetMediator), {:tweet, data})
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
#     GenServer.cast(Process.whereis(:TweetMediator), {:tweet, data})
#     {:noreply, state}
#   end
# end

# defmodule MyApp do
#   def run do
#     lambda = 50
#     min_workers = 3
#     batch_size = 10
#     time_window = 50
#     {:ok, reader_supervisor_pid} = SSEReaderSupervisor.start_link()
#     TweetMediator.start_link([lambda, min_workers])
#     RetweetAggregator.start_link()
#     Aggregator.start_link()
#     TweetBatcher.start_link(batch_size, time_window)

#     :timer.sleep(5000)
#     Process.exit(reader_supervisor_pid, :normal)
#   end
# end

# MyApp.run()
