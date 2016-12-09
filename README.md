Alinex Database: Readme
=================================================

[![GitHub watchers](
  https://img.shields.io/github/watchers/alinex/node-database.svg?style=social&label=Watch&maxAge=2592000)](
  https://github.com/alinex/node-database/subscription)
<!-- {.hidden-small} -->
[![GitHub stars](
  https://img.shields.io/github/stars/alinex/node-database.svg?style=social&label=Star&maxAge=2592000)](
  https://github.com/alinex/node-database)
[![GitHub forks](
  https://img.shields.io/github/forks/alinex/node-database.svg?style=social&label=Fork&maxAge=2592000)](
  https://github.com/alinex/node-database)
<!-- {.hidden-small} -->
<!-- {p:.right} -->

[![npm package](
  https://img.shields.io/npm/v/alinex-database.svg?maxAge=2592000&label=latest%20version)](
  https://www.npmjs.com/package/alinex-database)
[![latest version](
  https://img.shields.io/npm/l/alinex-database.svg?maxAge=2592000)](
  #license)
<!-- {.hidden-small} -->
[![Travis status](
  https://img.shields.io/travis/alinex/node-database.svg?maxAge=2592000&label=develop)](
  https://travis-ci.org/alinex/node-database)
[![Coveralls status](
  https://img.shields.io/coveralls/alinex/node-database.svg?maxAge=2592000)](
  https://coveralls.io/r/alinex/node-database?branch=master)
[![Gemnasium status](
  https://img.shields.io/gemnasium/alinex/node-database.svg?maxAge=2592000)](
  https://gemnasium.com/alinex/node-database)
[![GitHub issues](
  https://img.shields.io/github/issues/alinex/node-database.svg?maxAge=2592000)](
  https://github.com/alinex/node-database/issues)
<!-- {.hidden-small} -->

The database module allows connections to different databases easy configurable
and usable with query language builder.

The main features are:

- different rdbms and other databases
- pooling and cluster support
- easy access functions
- connections through automatic ssh tunnels
- object to query language bridge

> It is one of the modules of the [Alinex Namespace](https://alinex.github.io/code.html)
> following the code standards defined in the [General Docs](https://alinex.github.io/develop).

__Read the complete documentation under
[https://alinex.github.io/node-database](https://alinex.github.io/node-database).__
<!-- {p: .hidden} -->


Install
-------------------------------------------------

[![NPM](https://nodei.co/npm/alinex-database.png?downloads=true&downloadRank=true&stars=true)
 ![Downloads](https://nodei.co/npm-dl/alinex-database.png?months=9&height=3)
](https://www.npmjs.com/package/alinex-database)

The easiest way is to let npm add the module directly to your modules
(from within you node modules directory):

``` sh
npm install alinex-config - -save
```

And update it to the latest version later:

``` sh
npm update alinex-config --save
```

Always have a look at the latest [changes](Changelog.md).

### PostgreSQL Native Driver

To use the faster native driver you only have to install it:

``` sh
sudo apt-get install -y libpq-dev
npm install -g pq-native
```

It is used automatically if installed.


Usage
-------------------------------------------------

You can use different level of abstraction as you like.

### Only connection handling

The following example shows a complete and simple query transaction using
a mysql database:

``` coffee
# load the module
database = require 'alinex-database'

# get an instance
database.instance 'test-mysql', (err, db) ->
  throw err if err
  # get a new connection from the pool
  db.connect (err, conn) ->
    # query some values
    conn.query 'SELECT 2 + 2 AS solution', (err, rows, fields) ->
      throw err if err
      # do something with the results
      console.log 'The database calculated 2+2 =', rows[0].solution
      # give connection back
      conn.release()
      # close database
      db.close (err) ->
```

The configuration for the connection is done in the `database` section of the
configuration used via [Config](http://alinex.github.io/node-config).

### Easy Access

Instead of using the native `conn...` directly you may use the higher methods:

- `list()` - get an array of record objects
- `record()` - get one record as object
- `value()` - get the value of the first field
- `column()` - get an array of values from the first column
- `exec()` - update/insert or other execution statements

This may be called in three ways:

1.  call them on the database module:
    Therefore give the database alias as first parameter like:
    `database.exec 'my-db', 'SELECT...', [data], (err) -> ...`
2.  call them on the database instance:
    So you can remove the first parameter:
    `db.exec 'SELECT...', [data], (err) -> ...`
3.  also give a connection instance as first argument:
    This way you may run multiple commands on the same connection:
    `db.exec conn, 'SELECT...', [data], (err) -> ...`

If you run multiple queries on the same database better use solution (2) and
if you have statements which use common variables or transactions you need to
use (3).

__Example:__

Call with method (1) using the database module:

``` coffee
database.record 'my-database', 'SELECT * FROM user WHERE ID=5', (err, record) ->
  return cb err if err
```

Call with method (2) using the db instance:

``` coffee
database.instance 'my-database', (err, db) ->
  return cb err if err
  db.record 'SELECT * FROM user WHERE ID=5', (err, record) ->
    return cb err if err
```

Call with method (3) on connection:

``` coffee
database.instance 'my-database', (err, db) ->
  return cb err if err
  # get a new connection from the pool
  db.connect (err, conn) ->
    return cb err if err
    db.record conn, 'SELECT * FROM user WHERE ID=5', (err, record) ->
      return cb err if err
      # if you acquire a connection yourself don't forget to release it
      conn.release()

```

__Additional Possibilities:__

With this methods you can also use one of the higher SQL Builders:

- using placeholder for variables
- definition as object structure

They make it easier readable and helps preventing problems. See the description
below.

### Streaming

For large data sets, please use the native streaming possibilities till we can
implement some common behavior here.


Databases
-------------------------------------------------

The different supported databases have a lot in common, but differ in some ways.

In general you always can use only the connection handling using `db.connect()`
to get a connection of the database driver behind. If you want to use this directly
look at the API behind each abstraction layer.

### MySQL

Use the [Driver API](https://github.com/felixge/node-mysql) if you want to work
directly on the retrieved connections.

You can also use ? and ?? placeholder syntax from the driver.

Here you need to know that if you use * as field specifier the same name may
occur multiple times in the result set, so that they override each over in the
resulting object and the last one will be visible. To prevent this specify this
columns with an alias name.


### PostgreSQL

Use the [Driver API](https://github.com/brianc/node-postgres) if you want to work
directly on the retrieved connections.

You can use the native $1... placeholder syntax or the common supported '?' syntax
from the driver.


Query Language
-------------------------------------------------

### Placeholder Syntax
You may write your query like done normal as string but instead inserting the
values and esacaping them you may use `?` as a placeholder and give your values
in an array. They will be automatically be replaced with their correct escaped value.

Therefore you give the dataset as the second argument:

``` coffee
conn.query 'SELECT name FROM address WHERE age > ? and name = ?',
[30, 'alf']
```

This will also format the date database specific. And you may also replace with
objects:

``` coffee
conn.query 'INSERT INTO address SET ?',
  name: 'Alf'
  age: 56
```

### Object Language

The next possibility is to use a complete object notation instead of a string as
a query. See {@link src/object-lang.md}


Debugging
-------------------------------------------------
If you have any problems you may debug the code with the predefined flags. It uses
the debug module to let you define what to debug.

Call it with the DEBUG environment variable set to the types you want to debug.
The most valueable flags will be:

    DEBUG=database           # general information and checking schema
    DEBUG=database:cmd       # to show sql commands
    DEBUG=database:data      # to show the data transferred

You can also combine them using comma or use only DEBUG=* to show all.

Additional value checking will be done if the debugging for the general `database`
is enabled.


License
-------------------------------------------------

(C) Copyright 2015-2016 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
