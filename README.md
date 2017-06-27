# Igc

[![Build Status](https://circleci.com/gh/balexand/igc/tree/master.svg?style=shield)](https://circleci.com/gh/balexand/igc)
[![Hex Package](http://img.shields.io/hexpm/v/igc.svg?style=flat)](https://hex.pm/packages/igc)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/igc/)

Library for parsing IGC paragliding track files.

## Installation

The package can be installed by adding `igc` to your list of dependencies in
`mix.exs`:

```elixir
def deps do
  [{:igc, "~> 0.2.0"}]
end
```

## Usage

```elixir
{:ok, track} = Igc.parse("HFDTE280709\nB1101355206343N00006198WA0058700558")
```

The docs can be found at [https://hexdocs.pm/igc](https://hexdocs.pm/igc).
