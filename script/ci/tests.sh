#!/bin/bash

export MIX_ENV="test"
export PATH="$HOME/dependencies/phantomjs/bin:$HOME/dependencies/erlang/bin:$HOME/dependencies/elixir/bin:$PATH"

# Start headless browser server used by javascript-enabled acceptance tests
# Don't hide it's output since it can show javascript errors.
phantomjs -w --webdriver-loglevel=ERROR &
sleep 2

mix test
