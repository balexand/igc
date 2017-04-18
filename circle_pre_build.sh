#!/bin/bash

# Ensure exit codes other than 0 fail the build
set -e
# Check for asdf
if ! asdf | grep version; then
 git clone https://github.com/HashNuke/asdf.git ~/.asdf;

 asdf plugin-add erlang https://github.com/HashNuke/asdf-erlang.git
 asdf plugin-add elixir https://github.com/HashNuke/asdf-elixir.git
fi

export erlang_version=19.3
export elixir_version=1.4.2

# Write .tool-versions
echo "erlang $erlang_version" >> .tool-versions
echo "elixir $elixir_version" >> .tool-versions
# Install erlang/elixir
asdf install erlang $erlang_version
asdf install elixir $elixir_version
# Get dependencies
yes | mix deps.get
mix local.rebar --force
# Exit successfully
exit 0
