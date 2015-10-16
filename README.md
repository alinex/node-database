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

To query the database you may also use one of the higher methods:

- using placeholder for variables
- definition as object structure

They make it easier readable and helps preventing problems. See the description
below.

And instead of using the `query()` method you may also use some of the higher methods:

- `list()` - egt an array of record objects
- `record()` - get one record as object
- `value()` - get the value of the first field
- `column()` - get an array of values from the first column


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

### MySQL

The first driver implemented was the mysql driver.


Placeholder Syntax
-------------------------------------------------
You may write your query like done normal as string but instead inserting the
values and esacaping them you may use `?` as a placeholder and give your values
in an array. They will be automatically replaced with their correct escaped value.

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

- @... for names like tabel and fields
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
### TODO #############################################################################

# function $distinct $count

where:
  age:
    $or: [15, 30]
  name:
    $like: 'a%' # $or
  age:
    $gt: '@maxage'

group: 'age'
group: [...]

having:

order: 'age'
order: [...]
order:
  num: 'desc'
order: [
  $concat: []
  sort: 'asc'
,
  num: 'asc'
]

limit: 5
offset: 10





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
