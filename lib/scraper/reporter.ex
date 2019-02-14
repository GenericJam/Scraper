defmodule Scraper.Reporter do
  alias Scraper.Fields

  @doc """
  This pops the next url and returns the rest to state
  """
  def get_next_url do
    GenServer.call(__MODULE__, :get_next_url)
  end

  def report_results(results) do
    GenServer.cast(__MODULE__, {:report_results, results})
  end

  @doc """
  This gets the server initialized
  """
  def init({:urls, urls}) do
    # urls = Fields.default_urls()
    {:ok, %{:urls => urls}}
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
    IO.puts(inspect(results, pretty: true))
    {:noreply, state}
  end
end
