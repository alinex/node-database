# Object to SQL  Mapping
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('db')
chalk = require 'chalk'
{object, string} = require 'alinex-util'

# Conversion routines
# -------------------------------------------------

module.exports = (data, driver) ->
  # validate
  if debug.enabled
    validator = require 'alinex-validator'
    validator.check
      name: 'sqlObject'
      value: data
      schema: require "./driver/#{driver.conf.server.type}Schema"
    , (err, result) ->
      debug chalk.red "Error in SQL Object: #{err.message}" if err
  # select main type
  for name in Object.keys type
    continue unless data[name]?
    return type[name] data, driver
  # default handling of unknown names
  Object.keys data
  .map (e) -> "#{e} #{data[e]}"
  .join ' '

type =
  select: (data, driver) ->
    sql = "SELECT #{selectField data.select, driver}"
    sql += from data.from, driver
  update: (data, driver) ->
  insert: (data, driver) ->
  delete: (data, driver) ->
    sql = "DELETE"
    sql += from data.from, driver

# value or id
escape = (value, driver) ->
  if value is '?'
    value
  else if value[0] is '@'
    driver.escapeId value[1..]
  else
    driver.escape value
# always an id
escapeId = (value, driver) ->
  if value[0] is '@'
    driver.escapeId value[1..]
  else
    driver.escapeId value

selectField = (field, driver) ->
  switch
    when field is '*'
      field
    when typeof field is 'string'
      if string.ends field, '.*'
        escape(field[0..-3], driver) + '.*'
      else
        escape field, driver
    when Array.isArray field
      field.map (e) -> selectField e, driver
      .join ', '
    else # object
      Object.keys field
      .map (k) ->
        selectField(field[k], driver) + ' AS ' + escapeId k, driver
      .join ', '

from = (obj, driver) ->
  return '' unless obj?
  ' FROM ' + switch
    when typeof obj is 'string'
      escape obj, driver
    when Array.isArray obj
      obj.map (e) -> "#{escape e, driver}"
      .join ', '
    else # object
      Object.keys obj
      .map (k) ->
        escape(obj[k], driver) + ' AS ' + driver.escapeId k, driver
      .join ', '

