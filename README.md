# sqlite_adapter.cr [![Build Status](https://travis-ci.org/trapped/sqlite_adapter.cr.svg?branch=master)](https://travis-ci.org/trapped/sqlite_adapter.cr)

SQLite3 adapter for [active_record.cr](https://github.com/waterlink/active_record.cr). Uses [crystal-sqlite3](https://github.com/manastech/crystal-sqlite3) as driver.

## Installation

Add it to your `shard.yml`:

```yml
dependencies:
  sqlite_adapter:
    github: trapped/sqlite_adapter.cr
    version: 0.1.0
```

## Usage

By default `./data.db` is used as storage. You can set `SQLITE_DB` in your ENV to override it (`:memory:` works too).

```crystal
require "active_record"
require "sqlite_adapter"

class Person < ActiveRecord::Model
  adapter sqlite
  # ...
end
```

## Running tests

After running `crystal deps` or `crystal deps update`:

```
git submodule init
git submodule update
make test
```
