defmodule ScraperTest do
  use ExUnit.Case

  alias ScraperTest.Root
  alias Scraper.Utils
  alias Scraper.Server
  alias Scraper.Fields

  doctest Scraper.Utils

  def init(init_arg) do
    {:ok, init_arg}
  end

  test "gets searched value" do
    [searched] =
      Root.root() |> Utils.body_from_root() |> Utils.get_nodes_by_attributes(Root.search_terms())

    assert searched == %{:label => "test", :node => [Root.test_node()]}
  end
end
