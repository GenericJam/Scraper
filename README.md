# Scraper

This scrapes a list of URLs using the list supplied in /lib/scraper/fields.ex.
It looks for elements to scrape using the list of tags which lead into to target element.

```
<div id="super">
  <p class="dee">
    <h2 class="duper">This is a title</h2>
  </p>
  <div class="nonethat">
    <p>Other text</p>
  </div>
</html>
```

Put something like this in fields.ex. It is just for the purposes of disambiguation as classes aren't guaranteed to be unique in html so this is to give a unique location. The first one on the list is the one you expect to hit first (most outer or general) and they become more specific the further down the list you get.

```
[
  %{
    :label => "title",
    :list => [
      ["id", "super"],
      ["class", "duper"]
    ]
  },
  ...
]
```

## Installation

Download it using git or the like.

git clone https://github.com/GenericJam/Scraper.git

Make sure you have [Elixir](https://elixir-lang.org/install.html) (v >1.8.0) and Erlang (v ~21) installed.

You also need [headless Chrome](https://developers.google.com/web/updates/2017/04/headless-chrome). If you have a recent version of Chrome, you probably already have it. You may need to figure out how to run it on your system, though. On some it will be google-chrome, chrome or chrome.exe. This is run from a terminal. This will just keep going in the background until you stop it or close the terminal.

```
google-chrome-stable --headless --remote-debugging-port=9222  --blink-settings=imagesEnabled=false
```

Assuming all of the prep work is done, you need to install dependencies.

```
mix deps
```

Start it.

```
iex -S mix
```

Run it from within iex.

```
iex>Scraper.Application.run
```
