# FAF.PTR16.1 -- Project 0
> **Performed by:** Cernei Ion, group FAF-201

> **Verified by:** asist. univ. Alexandru Osadcenco

## P0W1

**Task 1** -- Greeter
```elixir
defmodule Greeter do
  def hello do
    "Hello PTR"
  end

  def start do
    IO.puts(hello())
  end
end

Greeter.start()
```

This is a script that would print the message “Hello PTR” on the screen.

**Task 2** -- Unit test

```elixir
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
```

This is a unit test for the first task. It asserts whether the function hello() returns "Hello PTR" and the function start() prints it.

## P0W2
Week 2 had 18 tasks, some of them are:

**Task 1** -- Roman Numerals

```elixir
defmodule RomanNumeral do
  def encode(0), do: ''
  def encode(x) when x >= 1000, do: [?M | encode(x - 1000)]
  def encode(x) when x >= 100, do: digit(div(x, 100), ?C, ?D, ?M) ++ encode(rem(x, 100))
  def encode(x) when x >= 10, do: digit(div(x, 10), ?X, ?L, ?C) ++ encode(rem(x, 10))
  def encode(x) when x >= 1, do: digit(x, ?I, ?V, ?X)

  defp digit(1, x, _, _), do: [x]
  defp digit(2, x, _, _), do: [x, x]
  defp digit(3, x, _, _), do: [x, x, x]
  defp digit(4, x, y, _), do: [x, y]
  defp digit(5, _, y, _), do: [y]
  defp digit(6, x, y, _), do: [y, x]
  defp digit(7, x, y, _), do: [y, x, x]
  defp digit(8, x, y, _), do: [y, x, x, x]
  defp digit(9, x, _, z), do: [x, z]
end
```

This module provides a function for encoding integers as Roman numerals. The encode function takes an integer and returns a string representing the Roman numeral equivalent of that number. 

The function is defined using pattern matching and guards to handle different ranges of numbers. The first function clause handles the case where the input is zero, and simply returns an empty string. The next three clauses handle numbers greater than or equal to 1000, 100, and 10. These clauses use the div and rem functions to split the input number into its most significant digit and the rest of the number. The digit function is then used to convert the digit into its Roman numeral equivalent, and the function recursively calls itself on the remaining number to encode the rest of the number. The final function clause handles numbers from 1 to 9. It uses the digit function to encode the single digit as a Roman numeral.

The digit function takes a digit and three characters representing the Roman numeral symbols for that digit's place value. It returns a list of characters representing the Roman numeral equivalent of the digit. The function uses pattern matching to handle the nine possible cases for the input digit, based on whether it is 1, 2, 3, 4, 5, 6, 7, 8, or 9.

**Task 2** -- Prime Factorization

```elixir
defmodule PrimeFactorization do
  def prime_factors(n, i \\ 2, factors \\ []) do
    if n <= 1 do
      factors
    else
      if rem(n, i) == 0 do
        prime_factors(trunc(n / i), i, [i | factors])
      else
        if i >= n do
          [n | factors]
        else
          prime_factors(n, i + 1, factors)
        end
      end
    end
  end
end
```

This module implements the recursive algorithm to find the prime factors of a given positive integer n. The function takes three arguments: n is the integer to be factored, i is the current divisor (defaulted to 2), and factors is the list of prime factors found so far (defaulted to an empty list). The final output of the prime_factors function is the list of prime factors in descending order. The algorithm starts with the smallest prime number, 2, and tests if n is divisible by it. If n is divisible by i, the algorithm divides n by i and recursively calls prime_factors with the quotient, n / i, and the same divisor, i. This is done until n is no longer divisible by i. When n is not divisible by i, the algorithm moves on to the next prime number, which is i + 1. If i is greater than or equal to n, it means that n is a prime number itself and it is added to the list of factors.

**Task 3** -- Longest Common Prefix

```elixir
defmodule CommonPrefix do
  def common_prefix([]), do: ""

  def common_prefix(words) do
    shortest_word = Enum.min_by(words, &String.length/1)
    shortest_word_length = String.length(shortest_word)

    Enum.reduce(0..shortest_word_length, "", fn index, acc ->
      common = String.slice(shortest_word, 0, index)

      if Enum.all?(words, &String.starts_with?(&1, common)) do
        common
      else
        String.slice(acc, 0, index - 1)
      end
    end)
  end
end
```

This implementation first finds the shortest word in the input list, using Enum.min_by. It then uses the length of this word to iterate over each possible common prefix of the word (i.e. all possible substring lengths from 0 to the length of the shortest word). For each possible common prefix, the implementation checks if it is a prefix of all the words in the input list using Enum.all? and String.starts_with?. If it is, the implementation sets this as the current longest common prefix. If it is not, the implementation returns the previous longest common prefix (which should be the longest common prefix up to the previous index).

## P0W3
Week 3 had 8 tasks, some of them are:

**Task 1** -- Semaphore

```elixir
defmodule Semaphore do
  def start(count) do
    spawn_link(fn -> init(count) end)
  end

  defp init(count) do
    receive do
      {:acquire, sender} ->
        if count > 0 do
          send(sender, :ok)
          init(count - 1)
        else
          init(count)
        end

      {:release, sender} ->
        send(sender, :ok)
        init(count + 1)
    end
  end

  def acquire(semaphore) do
    send(semaphore, {:acquire, self()})

    receive do
      :ok ->
        :ok
    end
  end

  def release(semaphore) do
    send(semaphore, {:release, self()})

    receive do
      :ok ->
        :ok
    end
  end
end
```

This is an implementation of a semaphore in Elixir. A semaphore is a synchronization primitive that limits access to a shared resource by multiple processes.

start(count): Starts the semaphore process with an initial count of count. init(count): waits for messages from other processes and handles them accordingly. When a process wants to acquire the semaphore, it sends a {:acquire, sender} message to the semaphore process. If the current count is greater than zero, the semaphore grants access by sending an :ok message back to the sender and decrements the count. If the count is zero, the semaphore doesn't grant access and simply waits for another request. When a process releases the semaphore, it sends a {:release, sender} message to the semaphore process. The semaphore increments the count and sends an :ok message back to the sender.

acquire(semaphore): This function is used by a process to acquire the semaphore. It sends a {:acquire, self()} message to the semaphore process and waits for an :ok message back, indicating that access has been granted. If multiple processes are waiting to acquire the semaphore, they will be served in a first-come-first-served basis. release(semaphore): This function is used by a process to release the semaphore. It sends a {:release, self()} message to the semaphore process and waits for an :ok message back, indicating that the semaphore has been released.

**Task 2** -- Risky task and Scheduler

```elixir
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
```

Overall, this implementation provides a simple way to manage a worker process that performs risky tasks and a scheduler process that supervises and restarts the worker process when it fails. It demonstrates some of the basic concurrency features of Elixir, such as process spawning and linking, message passing, and pattern matching.

When the worker process completes its task successfully, it sends a {:completed} message to the scheduler process. The scheduler simply prints a message indicating that the task was completed. When the worker process fails, it sends a {:failed, pid} message to the scheduler process, where pid is the process ID of the failed worker process. The scheduler prints a message indicating that the worker failed and restarts the worker process by calling RiskyTask.start/1 with the scheduler process as an argument.

RiskyTask.do_task(scheduler): This function performs the risky task. It generates a random number between 0 and 1 using :rand.uniform/0 and checks if it's less than 0.5. If it is, it sends a {:failed, self()} message to the scheduler process, where self() is the process ID of the current worker process. If it's greater than or equal to 0.5, it sends a {:completed} message to the scheduler process.

## P0W4

**Task 1** -- Supervised Worker Pool

```elixir
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

  ...

end
```

The Worker module defines a GenServer process that can receive messages and handle them accordingly. The WorkerSupervisor module defines a Supervisor process that starts a specified number of Worker processes as children. The Worker module has two handle_cast functions. One handles the :kill message, which exits the process. The other handles any other message and simply logs it. The WorkerSupervisor module has three functions. start_link starts a supervisor process with a specified number of child processes. init initializes the supervisor by registering the supervisor process and starting the specified number of child processes. send_message sends a message to a specified Worker process. worker_pids returns a list of the child process PIDs.

**Task 2** -- String Cleaner

```elixir
defmodule StringSplitter do
  use GenServer

  ...

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

  ...

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

  ...

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
  ...
end
```

Overall, this code demonstrates a simple example of how GenServers can be used to implement a pipeline of processing tasks on a given input. The StringCleanerSupervisor module is the top-level supervisor that starts three child GenServers: StringSplitter, StringLowercaser, and StringJoiner. Each child GenServer performs a specific task on the input string and sends the result to the next child GenServer. StringSplitter takes a string input and splits it into a list of words by whitespace. The resulting list is sent to StringLowercaser. StringLowercaser takes the list of words, lowercases each word, replaces all occurrences of "n" with "m" and all occurrences of "n" with "m". The resulting list is sent to StringJoiner. StringJoiner takes the list of cleaned words, joins them into a single string separated by a single whitespace character, and prints the resulting string to the console.

## P0W5

**Task 1** -- Quotes scrapper

```elixir
defmodule ScrapeQuotes do
  @base_url "https://quotes.toscrape.com/"

  def scrape_to_http() do
    {:ok, response} = HTTPoison.get(@base_url)
    IO.puts("Status code: #{response.status_code}")
    IO.puts("Headers: #{inspect(response.headers)}")
    IO.puts("Body: #{response.body}")
  end

  def scrape_to_quotes() do
    {:ok, response} = HTTPoison.get(@base_url)
    quotes = extract_quotes(response.body)
    IO.inspect(quotes)
  end

  def scrape_to_json() do
    {:ok, response} = HTTPoison.get(@base_url)
    quotes = extract_quotes(response.body)
    File.write("quotes.json", Jason.encode!(quotes))
  end

  def extract_quotes(response_body) do
    {:ok, doc} = Floki.parse_document(response_body)
    quote_elements = Floki.find(doc, ".quote")

    Enum.map(quote_elements, fn quote_element ->
      author =
        Floki.find(quote_element, ".author")
        |> List.first()
        |> Floki.text()

      text =
        Floki.find(quote_element, ".text")
        |> List.first()
        |> Floki.text()

      tags =
        Floki.find(quote_element, ".tag")
        |> Enum.map(&Floki.text/1)

      %{
        author: author,
        text: text,
        tags: tags
      }
    end)
  end
end
```

Overall, this module demonstrates how to use Elixir and its libraries to scrape and extract data from websites. scrape_to_http(): sends an HTTP GET request to the base URL using HTTPoison, and prints out the response status code, headers, and body. scrape_to_quotes(): extracts quotes from the response body using extract_quotes/1, and prints them out. scrape_to_json(): extracts quotes from the response body using extract_quotes/1, encodes them as JSON and writes the JSON data to a file called quotes.json. extract_quotes(response_body): takes the HTML response body as input, parses it using Floki.parse_document/1, finds all the quote elements using the CSS selector .quote and Floki.find/2, and extracts the author, text, and tags for each quote. Returns a list of maps containing the extracted data.

**Task 2** -- Start Wars themed API

```elixir
defmodule StarWarsApiWeb.MovieController do
  use StarWarsApiWeb, :controller

  alias StarWarsApi.Movies
  alias StarWarsApi.Movies.Movie

    def index(conn, _params) do
    movies = Movies.list_movies()
    render(conn, :index, movies: movies)
  end

  def create(conn, %{"movie" => movie_params}) do
    with {:ok, %Movie{} = movie} <- Movies.create_movie(movie_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/movies/#{movie}")
      |> render(:show, movie: movie)
    end
  end

  def show(conn, %{"id" => id}) do
    movie = Movies.get_movie!(id)
    render(conn, :show, movie: movie)
  end

  def update(conn, %{"id" => id, "movie" => movie_params}) do
    movie = Movies.get_movie!(id)

    with {:ok, %Movie{} = movie} <- Movies.update_movie(movie, movie_params) do
      render(conn, :show, movie: movie)
    end
  end

  def patch(conn, %{"id" => id, "movie" => movie_params}) do
    movie = Movies.get_movie!(id)

    with {:ok, %Movie{} = movie} <- Movies.patch_movie(movie, movie_params) do
      render(conn, :show, movie: movie)
    end
  end

  def delete(conn, %{"id" => id}) do
    movie = Movies.get_movie!(id)

    with {:ok, %Movie{}} <- Movies.delete_movie(movie) do
      send_resp(conn, :no_content, "")
    end
  end
end
```
This is an example of a controller module in Elixir's Phoenix web framework for managing movies in a Star Wars API. The index function retrieves a list of movies using the list_movies function from the Movies module and renders the index template with the retrieved movies. The create function receives a movie parameter, creates a new movie using create_movie function from the Movies module and renders the show template with the created movie. The show function retrieves a movie by its ID using the get_movie! function from the Movies module and renders the show template with the retrieved movie. The update function updates an existing movie by its ID using the update_movie function from the Movies module and renders the show template with the updated movie. The patch function updates specific fields of an existing movie by its ID using the patch_movie function from the Movies module and renders the show template with the updated movie. The delete function deletes an existing movie by its ID using the delete_movie function from the Movies module and sends a no_content response to the client.

## Conclusion

By working on this project, I gained an understanding of functional programming concepts, which are an essential part of Elixir's design philosophy. By working on tasks that involve creating and managing actors, understanding how supervisors work, and building RESTful APIs, I got hands-on experience with some of the essential tools and frameworks that Elixir provides (GenServer, Supervisor, HTTPoison, Floki, Jason, Phoenix). In conclusion, this project was an excellent way to gain a comprehensive understanding of Elixir's core concepts and features.

## Bibliography
https://elixir-lang.org/

https://hexdocs.pm/elixir/1.13/

https://hexdocs.pm/elixir/1.13/Enum.html

https://hexdocs.pm/elixir/1.13/Atom.html

https://hexdocs.pm/elixir/1.13/Function.html

https://hexdocs.pm/elixir/1.13/Map.html

https://hexdocs.pm/elixir/1.13/Process.html

https://hexdocs.pm/elixir/1.13/Supervisor.html

https://hexdocs.pm/elixir/1.13/GenServer.html

https://hexdocs.pm/httpoison/HTTPoison.html

https://hexdocs.pm/floki/Floki.html

https://hexdocs.pm/phoenix/up_and_running.html
