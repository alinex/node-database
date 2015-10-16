# Object to SQL  Mapping
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('db')
chalk = require 'chalk'
{object, string} = require 'alinex-util'

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


# Conversion of Subparts
# -------------------------------------------------

# ### SELECT field
field = (obj, driver) ->
  switch
    when obj is '*'
      obj
    when typeof obj is 'string'
      if string.ends obj, '.*'
        escape(obj[0..-3], driver) + '.*'
      else
        escape obj, driver
    when Array.isArray obj
      obj.map (e) -> field e, driver
      .join ', '
    else # object
      Object.keys obj
      .map (k) ->
        field(obj[k], driver) + ' AS ' + escapeId k, driver
      .join ', '

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
        escapeId("#{base}.#{k}", driver) + ' = ' + escape(obj[k], driver)
      .join ' AND '


# Conversion of SQL Parts
# -------------------------------------------------

# #### FROM
from = (obj, driver) ->
  return '' unless obj?
  ' FROM ' + table obj, driver

# Conversion of Main Types
# -------------------------------------------------

type =

  # ### SELECT
  select: (obj, driver) ->
    sql = "SELECT #{field obj.select, driver}"
    sql += from obj.from, driver

  # ### UPDATE
  update: (obj, driver) ->

  # ### INSERT
  insert: (obj, driver) ->

  # ### DELETE
  delete: (obj, driver) ->
    sql = "DELETE"
    sql += from obj.from, driver


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
    , (err, result) ->
      debug chalk.red "Error in SQL Object: #{err.message}" if err
  # select main type
  for name in Object.keys type
    continue unless obj[name]?
    return type[name] obj, driver
  # default handling of unknown names
  Object.keys obj
  .map (e) -> "#{e} #{obj[e]}"
  .join ' '

module.exports.schema = -> require './object2sql_schema'

