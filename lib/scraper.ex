defmodule Scraper do
  @moduledoc """
  Documentation for Scraper.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Scraper.hello()
      :world

  """
  def hello do
    :world
  end

  def start_link(urls) when is_list(urls) do
    IO.puts("Scraper started with #{length(urls)} URLs.")
    Scraper.Application.start(0, urls)
  end

  def get_state do
    Scraper.Server.get_state()
  end
end
