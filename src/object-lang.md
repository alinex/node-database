Query Definition: Object Language
=================================================================

This language is used to make it possible to define the real query in an abstract,
object oriented way. It's influenced by the langauages used on all the different
database types but evolves in an common base, here.


General Notation
-----------------------------------------------------------------
To make the notation clean and prevent misleading situations the values have to
be prefixed with:

- @... for names like table and fields
- $... for functions
- ? used as value will be a placeholder like before and used with the given dataset

All other values are used as is and quoted or converted like needed.


Relational Databases
-----------------------------------------------------------------
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

### SELECT

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

### DISTINCT

If set the query will only return distinct (different) records:

``` yaml
distinct: true
```

### FROM

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

### WHERE

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

### Functions

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
