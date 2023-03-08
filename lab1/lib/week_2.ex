defmodule Prime do
  def is_prime?(n) when n <= 1 do
    false
  end

  def is_prime?(2) do
    true
  end

  def is_prime?(n) do
    Enum.all?(2..round(:math.sqrt(n)), fn x -> rem(n, x) != 0 end)
  end
end

IO.puts(Prime.is_prime?(9))

defmodule Cylinder do
  def area(height, radius) do
    2 * :math.pi() * radius * (radius + height)
  end
end

IO.puts(Cylinder.area(3, 4))

defmodule ListUtils do
  def reverse(list) do
    Enum.reverse(list)
  end

  def extract_random_elements(list, count) do
    Enum.take_random(list, count)
  end

  def sum_of_unique_elements(list) do
    Enum.uniq(list) |> Enum.sum()
  end

  def rotate_left(list, n) do
    {left, right} = Enum.split(list, n)
    right ++ left
  end

  def remove_consecutive_duplicates(list) do
    Enum.dedup(list)
  end
end

IO.inspect(ListUtils.reverse([1, 2, 4, 8, 4]))
IO.inspect(ListUtils.extract_random_elements([1, 2, 4, 8, 4], 3))
IO.inspect(ListUtils.sum_of_unique_elements([1, 2, 4, 8, 4, 4, 4, 2]))
IO.inspect(ListUtils.rotate_left([1, 2, 5, 10, 4, 5, 2], 4))
IO.inspect(ListUtils.remove_consecutive_duplicates([1, 2, 2, 2, 4, 8, 8, 4, 3]))

defmodule Fibonacci do
  def fib(0), do: 1
  def fib(1), do: 1
  def fib(n), do: fib(n - 2) + fib(n - 1)

  def n_fibonacci(n) do
    Enum.map(0..(n - 1), &Fibonacci.fib/1)
  end
end

IO.inspect(Fibonacci.n_fibonacci(10))

defmodule NumberUtils do
  def smallest_number(a, b, c) do
    digits = [a, b, c]

    digits
    |> Enum.sort()
    |> swap_zero_with_second_digit()
    |> Enum.join()
    |> to_string()
  end

  defp swap_zero_with_second_digit(list) do
    case list do
      [0 | rest] ->
        [Enum.at(rest, 0), 0 | Enum.drop(rest, 1)]
      _ ->
        list
    end
  end
end

IO.puts(NumberUtils.smallest_number(4, 5, 3))
IO.puts(NumberUtils.smallest_number(0, 3, 4))

defmodule Translator do
  def translate(dict, sentence) do
    sentence
    |> String.split()
    |> Enum.map(fn word -> String.to_atom(word) end)
    |> Enum.map(fn word -> Map.get(dict, word, word) end)
    |> Enum.map(fn word -> to_string(word) end)
    |> Enum.join(" ")
  end
end

dict = %{:mama => "mother", :papa => "father", :baby => "child", :casa => "home"}
original_string = "mama is with papa and baby at casa"
IO.puts(Translator.translate(dict, original_string))

defmodule PythagoreanTriplets do
  def find() do
    Enum.flat_map(1..20, &find_triplets_for_a(&1))
  end

  defp find_triplets_for_a(a) do
    Enum.map(1..20, fn b -> {a, b, :math.sqrt(:math.pow(a, 2) + :math.pow(b, 2))} end)
    |> Enum.filter(fn {_, _, c} -> c == Float.floor(c) end)
  end
end

IO.inspect(PythagoreanTriplets.find())

defmodule KeyboardRow do
  @first_row ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
  @second_row ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
  @third_row ["z", "x", "c", "v", "b", "n", "m"]

  def line_words(words) do
    words
    |> Enum.map(&String.downcase/1)
    |> Enum.map(&String.graphemes/1)
    |> Enum.filter(fn word -> one_row_word?(word) end)
    |> Enum.map(&Enum.join/1)
  end

  defp one_row_word?(word) do
    keyboard_rows = [@first_row, @second_row, @third_row]
    Enum.any?(keyboard_rows, fn keyboard_row -> all_in_row?(word, keyboard_row) end)
  end

  defp all_in_row?(word, keyboard_row) do
    Enum.all?(word, fn char -> Enum.member?(keyboard_row, char) end)
  end
end

IO.inspect(KeyboardRow.line_words(["Hello", "Alaska", "Dad", "Peace", "qwer", "hslgfq"]))

defmodule CaesarCipher do
  defp set_map(map, range, key) do
    org = Enum.map(range, &List.to_string([&1]))
    {a, b} = Enum.split(org, key)
    Enum.zip(org, b ++ a) |> Enum.into(map)
  end

  def encode(text, key) do
    map = Map.new() |> set_map(?a..?z, key) |> set_map(?A..?Z, key)
    String.graphemes(text) |> Enum.map_join(fn c -> Map.get(map, c, c) end)
  end

  def decode(ciphertext, shift) do
    encode(ciphertext, 26 - shift)
  end
end

IO.puts(CaesarCipher.encode("LoRem", 3))
IO.puts(CaesarCipher.decode("oruhp", 3))

defmodule PhoneNumber do
  def letter_combinations(number_string) do
    number_map = %{
      "2" => ["a", "b", "c"],
      "3" => ["d", "e", "f"],
      "4" => ["g", "h", "i"],
      "5" => ["j", "k", "l"],
      "6" => ["m", "n", "o"],
      "7" => ["p", "q", "r", "s"],
      "8" => ["t", "u", "v"],
      "9" => ["w", "x", "y", "z"]
    }

    String.graphemes(number_string)
    |> Enum.reduce([""], fn char, combinations ->
      Enum.flat_map(combinations, fn combination ->
        Enum.map(number_map[char], &(combination <> &1))
      end)
    end)
  end
end

IO.inspect(PhoneNumber.letter_combinations("99"))

defmodule AnagramGroup do
  def group(strings) do
    strings
    |> Enum.group_by(fn string ->
      string
      |> String.downcase()
      |> String.graphemes()
      |> Enum.sort()
    end)
    |> Enum.map(fn {key, values} ->
      {key |> Enum.join(""), values}
    end)
  end
end

IO.inspect(AnagramGroup.group(["eat", "tea", "tan", "ate", "nat", "bat"]))

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

IO.inspect(PrimeFactorization.prime_factors(42), charlists: :as_lists)

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

IO.puts(RomanNumeral.encode(13))

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

IO.inspect(CommonPrefix.common_prefix(["flower", "flow", "flight"]))
IO.inspect(CommonPrefix.common_prefix(["alpha", "beta", "gamma"]))
IO.inspect(CommonPrefix.common_prefix(["alpha", "alp", "alpal"]))
