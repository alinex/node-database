# Object to SQL  Mapping
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('db')
chalk = require 'chalk'
{string} = require 'alinex-util'

# General Helpers
# -------------------------------------------------

# ### Escape Value or ID
# - ? =>  keep placeholder
# - @... => escape as ID
# - else escape value
escape = (value, driver) ->
  if value is '?'
    value
  else if value[0] is '@'
    driver.escapeId value[1..]
  else
    driver.escape value

# ### Escape ID
escapeId = (value, driver) ->
  if value[0] is '@'
    driver.escapeId value[1..]
  else
    driver.escapeId value


# Functions
# -------------------------------------------------
func =
  # ### Comparison
  eq: (obj, driver) -> "= #{field obj, driver}"
  ne: (obj, driver) ->  "<> #{field obj, driver}"
  gt: (obj, driver) ->  "> #{field obj, driver}"
  lt: (obj, driver) ->  "< #{field obj, driver}"
  ge: (obj, driver) ->  ">= #{field obj, driver}"
  le: (obj, driver) ->  "<= #{field obj, driver}"
  like: (obj, driver) ->  "LIKE #{field obj, driver}"
  in: (obj, driver) ->  "IN(#{field obj, driver})"
  between: (obj, driver) ->
    "BETWEEN #{field obj.min, driver} AND #{field obj.max, driver}"

  # ### Group functions
  count: (obj, driver, as) -> "COUNT(#{field obj, driver, as})"

  # ### Special
  value: (obj, driver) -> "= #{escape obj, driver}"

# Conversion of Subparts
# -------------------------------------------------

# ### SELECT field
field = (obj, driver, as = true) ->
  switch
    when obj is '*'
      obj
    when typeof obj is 'string'
      if string.ends obj, '.*'
        escape(obj[0..-3], driver) + '.*'
      else
        escape obj, driver
    when Array.isArray obj
      obj.map (e) -> field e, driver, as
      .join ', '
    when typeof obj is 'object'
      Object.keys obj
      .map (k) ->
        if k[0] is '$'
          func[k[1..]] obj[k], driver
        else if as
          field(obj[k], driver, false) + ' AS ' + escapeId k, driver
        else
          escapeId(k, driver) + ' ' + field(obj[k], driver, as)
      .join ', '
    else
      escape obj, driver

# ### FROM table
table = (obj, driver) ->
  sql = switch
    when typeof obj is 'string'
      escape obj, driver
    when Array.isArray obj
      obj.map (e) -> table e, driver
      .join ', '
    else # object
      Object.keys obj
      .map (k) ->
        base = k
        e = obj[k]
        if typeof e is 'string'
          return escape(e, driver) + ' AS ' + escapeId k, driver
        sub = Object.keys e
        as = ''
        unless 'join' in sub and 'on' in sub
          as = ' AS ' + escapeId k, driver
          k = sub[0]
          e = e[k]
        join = "#{(e.join ? 'left').toUpperCase()} JOIN #{escapeId k, driver}#{as}"
        join += " ON #{condition e.on, driver, base}" if e.on?
      .join ', '
  sql.replace /,( [A-Z]+ JOIN)/, '$1'

# ### WHERE condition
condition = (obj, driver, base) ->
  switch
    when typeof obj is 'string'
      "ISSET #{escape obj, driver}"
    when Array.isArray obj
      obj.map (e) -> condition e, driver, base
      .join ' AND '
    else # object
      Object.keys obj
      .map (k) ->
        escapeId("#{if base then base+'.' else ''}#{k}", driver) + ' = ' + escape(obj[k], driver)
      .join ' AND '


# Conversion of SQL Parts
# -------------------------------------------------

# #### FROM
from = (obj, driver) -> " FROM #{table obj, driver}"

# #### FROM
where = (obj, driver) -> " WHERE #{condition obj, driver}"

# ### DISTINCT
distinct = (obj) ->
  if obj? then " DISTINCT" else ''

# Conversion of Main Types
# -------------------------------------------------

type =

  # ### SELECT
  select: (obj, driver) ->
    sql = "SELECT"
    sql += distinct obj.distinct, driver
    sql += " #{field obj.select, driver}"
    sql += from obj.from, driver if obj.from
    sql += where obj.where, driver if obj.where
    sql += ';'

  # ### UPDATE
  update: (obj, driver) ->

  # ### INSERT
  insert: (obj, driver) ->

  # ### DELETE
  delete: (obj, driver) ->
    sql = "DELETE"
    sql += from obj.from, driver
    sql += ';'


# Conversion
# -------------------------------------------------

module.exports = (obj, driver) ->
  # validate
  if debug.enabled
    validator = require 'alinex-validator'
    validator.check
      name: 'sqlObject'
      value: obj
      schema: require('./object2sql_schema').schema
    , (err) ->
      debug chalk.red "Error in SQL Object: #{err.message}" if err
  # select main type
  for name in Object.keys type
    continue unless obj[name]?
    return type[name] obj, driver
  # default handling of unknown names
  (Object.keys obj
  .map (e) -> "#{e} #{obj[e]}"
  .join ' '
  ) + ';'

module.exports.schema = -> require './object2sql_schema'
