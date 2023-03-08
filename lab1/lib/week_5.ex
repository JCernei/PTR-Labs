defmodule ScrapeQuotes do
  require HTTPoison
  require Floki
  require Jason

  :application.ensure_all_started(:hackney)
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

ScrapeQuotes.scrape_to_http()
ScrapeQuotes.scrape_to_quotes()
ScrapeQuotes.scrape_to_json()
