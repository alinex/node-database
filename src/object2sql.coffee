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

module.exports = (obj, driver) ->
  # validate
  if debug.enabled
    validator = require 'alinex-validator'
    validator.check
      name: 'sqlObject'
      value: obj
      schema: require "./driver/#{driver.conf.server.type}Schema"
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

type =
  select: (obj, driver) ->
    sql = "SELECT #{selectField obj.select, driver}"
    sql += from obj.from, driver
  update: (obj, driver) ->

selectField = (field, driver) ->
  switch
    when field is '*'
      field
    when typeof field is 'string'
      if string.ends field, '.*'
        driver.escapeId(field[0..-3]) + '.*'
      else
        driver.escapeId field
    when Array.isArray field
      field.map (e) -> selectField e, driver
      .join ', '
    else # object
      Object.keys field
      .map (k) ->
        selectField(field[k], driver) + ' AS ' + driver.escapeId k
      .join ', '

from = (obj, driver) ->
  return '' unless obj?
  ' FROM ' + switch
    when typeof obj is 'string'
      driver.escapeId obj
    when Array.isArray obj
      obj.map (e) -> "#{driver.escapeId e}"
      .join ', '
    else # object
      Object.keys obj
      .map (k) ->
        driver.escapeId obj[k] + ' AS ' + driver.escapeId k
      .join ', '

