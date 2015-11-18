Package: alinex-database
=================================================

[![Build Status](https://travis-ci.org/alinex/node-database.svg?branch=master)](https://travis-ci.org/alinex/node-database)
[![Coverage Status](https://coveralls.io/repos/alinex/node-database/badge.png?branch=master)](https://coveralls.io/r/alinex/node-database?branch=master)
[![Dependency Status](https://gemnasium.com/alinex/node-database.png)](https://gemnasium.com/alinex/node-database)

The database module allows connections to different databases easy configurable
and usable with query language builder.

The main features are:

- different rdbms and other databases
- pooling and cluster support
- easy access functions
- connections through automatic ssh tunnels
- object to query language bridge

> It is one of the modules of the [Alinex Universe](http://alinex.github.io/code.html)
> following the code standards defined in the [General Docs](http://alinex.github.io/node-alinex).


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

Call after method (2) with using the db instance:

``` coffee
database.instance 'my-database', (err, db) ->
  return cb err if err
  db.record 'SELECT * FROM user WHERE ID=5', (err, record) ->
    return cb err if err
```

Call on connection (3):

``` coffee
database.instance 'my-database', (err, db) ->
  return cb err if err
  # get a new connection from the pool
  db.connect (err, conn) ->
    return cb err if err
    db.record conn, 'SELECT * FROM user WHERE ID=5', (err, record) ->
      return cb err if err
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


Configuration
-------------------------------------------------

``` yaml
# Database setup
# =================================================

# Specific database
# -------------------------------------------------
<name>:

  # optional you may use a ssh tunnel to connect through
  ssh:

    # hostname or ip to connect to
    host: localhost
    # connection port
    port:  ssh
    # user to login as
    username: alex
    # (optionally) private key for login
    privateKey: <<<file:///home/alex/.ssh/id_rsa>>>
    # time for sending keepalive packets
    keepaliveInterval: 1s
    #debug: true

  # database server
  server:

    # type of database (mysql, postgresql, sqlite, mongodb, elasticsearch)
    type: mysql

    # the host and port of the database, if no port given the default for
    # this type is used
    host: <<<env://MYSQL_HOST | localhost>>>
    #port: <<<env://MYSQL_PORT | 3306>>>

    # name of the database or catalog
    database: <<<env://MYSQL_DATABASE | test>>>

    # authentication on the database server
    user: <<<env://MYSQL_USER | test>>>
    password: <<<env://MYSQL_PASSWORD | >>>

    # specific database settings
    #charset: UTF8_GENERAL_CI
    #timezone: local

    # timeout settings
    #connectTimeout: 10s

  # specific settings for pooling
  pool:

    # limit the parallel connections
    limit: 2
```


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

Here you need to know that if you use '*' as field specifier the same name may
occur multiple times in the result set, so that they override each over in the
resulting object and the last one will be visible. To prevent this specify this
columns with an alias name.


### PostgreSQL

Use the [Driver API](https://github.com/brianc/node-postgres) if you want to work
directly on the retrieved connections.

You can use the native $1... placeholder syntax or the common supported '?' syntax
from the driver.


Placeholder Syntax
-------------------------------------------------
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


Object to Query Language
-------------------------------------------------

The next possibility is to use a complete object notation instead of a string.


### General Notation

To make the notation clean and prevent misleading situations the values have to
be prefixed with:

- @... for names like table and fields
- $... for functions
- ? used as value will be a placeholder like before and used with the given dataset

All other values are used as is and quoted or converted like needed.


### Relational Databases

Here you define your query like an object. The structure looks much like the
SQL dialect itself to make it easy:

``` coffee
  conn.query
    select: '*'
    from: '@person'
    where:
      age: 30
      name: 'Alf'
  # SQL: SELECT * FROM `person` WHERE `age` = 30 AND `name` = 'Alf'
```

The object notation is easier to read and can be created step by step.
Also the object will be validated if run with `DEBUG=database*` flag.

The following description will explain all the possible keys (uppermost level)
of the object structure you give to create the SQL string.


#### SELECT

First you can define a single value defining what you want.

``` yaml
select: '@name'       # column name
select: '*'           # all columns
select: '@person.*'   # all columns of table person
```

Or give an array with multiple values:

``` yaml
select: ['@name', '@age'] # fields array
```

To give each column a specific alias name use an object:

``` yaml
select:
  PersonName: '@name'
```
 And at last you may also use functions:

``` yaml
select:
  $count: '*'
select:
  PersonName:
    $count: '*'
```

#### DISTINCT

If set the query will only return distinct (different) records:

``` yaml
distinct: true
```

#### FROM

Give the tables or catalogs to use.

``` yaml
from: '@person'
```

Or as an array (using a full join):

``` yaml
from: ['@person', '@address']
```

Also this may be named:

``` yaml
form:
  Person: @person
```

And with specific joins:

``` yaml
from:
  Person: @person
  Address:
    address:
      join: 'left'   # left, right, outer, inner
      on:            # join criteria
        ID: '@person.addressID'
        age:
          $gt: 5
# same defined as array
from: [
  '@person'
,
  Address:
    address:
      join: 'left'   # left, right, outer, inner
      on:            # join criteria
        ID: '@Person.addressID'
        age:
          $gt: 5
]
```

#### WHERE

Constraints can be defined using where. If no operator is given the field is
checked against equality to the given value:

``` yaml
where:
  age: 30
```

But you also can give any comparison operator of the ones listed below:

``` yaml
where:
  age:
    $gt: 30
```

#### Functions

__Comparison__

- eq - equal
- ne - not equal
- gt - greater than
- lt - lower than
- ge - greater or equal
- le - lower or equal
- like - like given pattern
- in - in list of values
- between - the given 'min' and 'max' values

__Group functions__

- count - number of entries

__Special__

- value - used if value is needed on the left side of operator


License
-------------------------------------------------

Copyright 2015 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
