defmodule Scraper.Reporter do
  alias Scraper.Fields
  alias Scraper.Utils

  @doc """
  This pops the next url and returns the rest to state
  """
  def get_next_url do
    GenServer.call(__MODULE__, :get_next_url)
  end

  @doc """
  This is called when the page is scraped so the function can pass its results
  """
  def report_results(results) do
    GenServer.cast(__MODULE__, {:report_results, results})
  end

  @doc """
  This gets the server initialized
  """
  def init({:urls, urls}) do
    # urls = Fields.default_urls()
    number_urls = length(urls)
    {:ok, %{:urls => urls, :number_urls => number_urls, :results => []}}
  end

  @doc """
  start_link starts the scraper with an initial list of URLs
  """
  def start_link(huh) do
    IO.puts(inspect(huh, pretty: true))
    urls = Fields.default_urls()
    GenServer.start_link(__MODULE__, {:urls, urls}, name: __MODULE__)
  end

  @doc """
  This is so the supervisor will run
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc """
  This partners with get_next_url to access GenServer state
  """
  def handle_call(:get_next_url, _from, state) do
    %{:urls => urls} = state

    if urls == [] do
      {:reply, nil, state}
    else
      [next_url | rest_urls] = urls
      {:reply, next_url, Map.merge(state, %{:urls => rest_urls})}
    end
  end

  @doc """
  This partners with report_results to update GenServer state
  """
  def handle_cast({:report_results, results}, state) do
    %{:results => state_results, :number_urls => number_urls} = state

    new_results = [results | state_results]
    new_state = Map.merge(state, %{:results => new_results})
    IO.puts(".. #{length(new_results)}")

    if number_urls == length(new_results) do
      process_results(new_results)
    end

    {:noreply, new_state}
  end

  def process_results(results) do
    IO.puts("Results of Scrape:")
    print_result(results)
  end

  def print_result([]) do
    IO.puts(
      "----------------------------------------------------------------------------------------"
    )

    IO.puts("End of results")
  end

  def print_result([result | rest]) do
    %{:url => url, :result => page_results} = result

    IO.puts(
      "----------------------------------------------------------------------------------------"
    )

    IO.puts("URL: #{url}")

    IO.puts(label_values(page_results))

    print_result(rest)
  end

  def label_values([]) do
    ""
  end

  def label_values([h | t]) do
    if h.label == "price" do
      "#{h.label} : #{
        h.value |> String.replace(".", "") |> String.replace(",", "") |> String.replace("-", "00")
      } | " <> label_values(t)
    else
      "#{h.label} : #{h.value} | " <> label_values(t)
    end
  end
end
