defmodule Scraper.Server do
  alias Scraper.Utils
  alias Scraper.Fields
  alias Scraper.Reporter

  @doc """
  start_link starts the scraper with an initial list of URLs
  """
  def start_link(urls) when is_list(urls) do
    urls = Fields.default_urls()
    IO.puts("Server running with #{length(urls)} URLs.")
    GenServer.start_link(__MODULE__, {:urls, urls}, name: __MODULE__)
    # Reporter.start_link(urls)
  end

  @doc """
  This is just a convenience to query the state
  """
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc """
  This gets the server initialized
  """
  def init({:urls, urls}) do
    server = ChromeRemoteInterface.Session.new()
    {:ok, %{:urls => urls, :server => server}}
  end

  @doc """
  This needs to be here to satisfy Elixir
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
  This is the function that kicks it off
  """
  def scrape do
    GenServer.call(__MODULE__, :scrape)
  end

  @doc """
  This partners with get_state
  """
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @doc """
  This partners with get_page
  """
  def handle_call(:scrape, _from, state) do
    %{:server => server} = state

    {:ok, pages} = ChromeRemoteInterface.Session.list_pages(server)

    # This creates more pages if there aren't already enough
    pages = get_create_pages(pages, server)

    Enum.each(pages, fn page ->
      # Create as many pages as needed (5)
      {:ok, page_pid} = ChromeRemoteInterface.PageSession.start_link(page)
      # This will return nil if the list is empty
      url = Reporter.get_next_url()
      spawn(Scraper.Server, :page_scrape, [page, server, url, page_pid])
    end)

    {:reply, state, state}
  end

  @doc """
  If there aren't already 5 pages open create them
  """
  def get_create_pages(pages, server) do
    if length(pages) < 5 do
      {:ok, page} = ChromeRemoteInterface.Session.new_page(server)
      get_create_pages([page | pages], server)
    else
      pages
    end
  end

  @doc """
  This is a guard for the end of the urls
  """
  def page_scrape(_page, _server, nil, _page_pid) do
    IO.puts("URLs all processed")
  end

  @doc """
  This will get used once per page - does most of the heavy lifting
  """
  def page_scrape(page, server, url, page_pid) do
    _navigation =
      ChromeRemoteInterface.RPC.Page.navigate(page_pid, %{
        "url" => url,
        "waitUntil" => "networkidle",
        "imagesEnabled" => false
      })

    %{"id" => page_id} = page

    # Block extra network calls if possible
    ChromeRemoteInterface.RPC.Page.setAdBlockingEnabled(page_pid)
    ChromeRemoteInterface.Session.activate_page(server, page_id)

    # depth -1 means all nodes in tree
    {:ok, root_1} = ChromeRemoteInterface.RPC.DOM.getDocument(page_pid, %{"depth" => 0})

    # Resolve Javascript on the root node
    ChromeRemoteInterface.RPC.DOM.resolveNode(page_pid, %{
      "backendNodeId" => root_1["result"]["root"]["backendNodeId"],
      "waitUntil" => "networkidle"
    })

    # This may need to be adjusted depending on the network or machine
    :timer.sleep(500)

    {:ok, root} = ChromeRemoteInterface.RPC.DOM.getDocument(page_pid, %{"depth" => -1})
    body = Utils.body_from_root(root)

    page_results = Utils.get_nodes_by_attributes(body, Fields.fields())

    IO.puts("Finished #{url}")

    Reporter.report_results(%{:url => url, :result => page_results})

    # Go get another url to scrape
    page_scrape(page, server, Reporter.get_next_url(), page_pid)
  end
end
