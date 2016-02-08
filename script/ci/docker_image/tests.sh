#!/bin/sh
set -e

export MIX_ENV=test

cd /app

export PATH="/app/node_modules/.bin:$PATH"

# Start headless browser server used by javascript-enabled acceptance tests
phantomjs -w > /dev/null &
sleep 1

mix test
