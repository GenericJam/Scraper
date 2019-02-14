defmodule Scraper.Utils do
  @doc """
  Gets document body from root node
  """
  def body_from_root(root) do
    [_h | [h2 | _t]] = root["result"]["root"]["children"]
    [_head | [body | _t]] = h2["children"]
    body
  end

  @doc """
  Gets document head from root node
  """
  def head_from_root(root) do
    [_h | [h2 | _t]] = root["result"]["root"]["children"]
    [head | _t] = h2["children"]
    head
  end

  @doc """
  Pulls text from a specified node that has text immediately in it eg <p>

  iex> Scraper.Utils.text_from_node( %{"attributes"=>[],"backendNodeId"=>810256,"childNodeCount"=>1,"children"=>[%{"backendNodeId"=>810257,"localName"=>"","nodeId"=>21,"nodeName"=>"#text","nodeType"=>3,"nodeValue"=>"yo","parentId"=>20}],"localName"=>"script","nodeId"=>20,"nodeName"=>"SCRIPT","nodeType"=>1,"nodeValue"=>"","parentId"=>5} )
  "yo"
  """
  def text_from_node(node) do
    # IO.puts(inspect(node, pretty: true))

    if node["children"] != nil do
      text_from_children(node["children"])
    end
  end

  @doc """
  Helper function for text_from_node
  recurses to find the #text node in the list of nodes

  iex> Scraper.Utils.text_from_children( [%{ "backendNodeId" => 810257, "localName" => "", "nodeId" => 21, "nodeName" => "#text", "nodeType" => 3, "nodeValue" => "yo", "parentId" => 20 }] )
  "yo"
  """
  def text_from_children([]) do
    IO.puts("Text not found")
    nil
  end

  @doc """
  Helper function for text_from_node
  recurses to find the #text node in the list of nodes
  """
  def text_from_children([h | t]) do
    if h["nodeName"] == "#text" do
      h["nodeValue"]
    else
      text_from_children(t)
    end
  end

  @doc """
  Final clause for get_node_by_attributes - nothing found in this list
  """
  def get_nodes_by_attributes(_root, []) do
    []
  end

  @doc """
  Traversing the list of nodes submitted

  iex> Scraper.Utils.get_nodes_by_attributes(Utils.body_from_root(ScraperTest.Root.root), ScraperTest.Root.search_terms)
  ScraperTest.Root.search_result
  """
  def get_nodes_by_attributes(root, [h | t]) do
    # IO.puts(inspect(h, pretty: true))
    node = get_node_by_attributes(root, h.list)
    [%{:label => h.label, :node => node} | get_nodes_by_attributes(root, t)]
  end

  @doc """
  Final clause for get_node_by_attribute - nothing found in this list

  """
  def get_node_by_attributes([], _nodeId) do
    []
  end

  @doc """
  Recursing the list using get_node_by_attribute
  """
  def get_node_by_attributes([h | t], look_for) do
    # Head should be a map and tail the rest of this list
    node = get_node_by_attributes(h, look_for)
    node ++ get_node_by_attributes(t, look_for)
  end

  @doc """
  Node has been found as the look_for is empty so it found the last specifier
  """
  def get_node_by_attributes(node, []) when is_map(node) do
    # Found the node!
    [node]
  end

  @doc """
  This is fed a map which could have lists or maps. This is the main function
  """
  def get_node_by_attributes(node, look_for) when is_map(node) do
    [lf_head | lf_tail] = look_for

    found_nodes =
      if check_for_attributes(node["attributes"], lf_head) do
        File.write("debug1.ex", inspect(node["children"], pretty: true))
        get_node_by_attributes(node, lf_tail)
      end

    found_nodes || [] ++ get_node_by_attributes(node["children"] || [], look_for)
  end

  @doc """
  Return true as one of the others will be false to make it fail
  """
  def check_for_attributes(_attr, []) do
    true
  end

  @doc """
  Guard for nil value
  """
  def check_for_attributes(nil, _look_for) do
    false
  end

  @doc """
  Check against list of typically two attributes eg [id, id-name] or [class, class-name]
  """
  def check_for_attributes(attributes, [look_for_h | look_for_t]) do
    Enum.member?(attributes, look_for_h) && check_for_attributes(attributes, look_for_t)
  end

  def check_for_attributes(attributes, huh) do
    IO.puts(inspect(attributes))
    IO.puts(inspect(huh))
  end
end
