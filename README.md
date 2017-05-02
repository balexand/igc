# Igc

Library for parsing IGC paragliding track files.

## Installation

The package can be installed by adding `igc` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [{:igc, "~> 0.1.0"}]
end
```

## Usage

```elixir
{:ok, track} = Igc.parse("HFDTE280709\nB1101355206343N00006198WA0058700558")
```

The docs can be found at [https://hexdocs.pm/igc](https://hexdocs.pm/igc).
