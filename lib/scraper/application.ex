defmodule Scraper.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @doc """
  This runs at compile time
  """
  def start(_type, urls) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Scraper.Worker.start_link(arg)
      {Scraper.Server, urls},
      {Scraper.Reporter, urls}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Scraper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Use this to launch the scrape
  """
  def run do
    Scraper.Server.scrape()
  end
end
