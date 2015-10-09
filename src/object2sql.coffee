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
      schema: driver.schema
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

  update: (obj, driver) ->

selectField = (field, driver) ->
  switch
    when field is '*'
      field
    when string.ends field, '.*'
      Driver.escapeID object.select[0..-33] + '.*'
    when typeof field is 'string'
      Driver.escapeID object.select
    when Array.isArray field
      field.map (e) -> selectField e, driver
      .join ', '
    else # object
      Object.keys field
      .map (k) ->
        selectField(field[k], driver) + ' AS ' + Driver.escapeID k
      .join ', '
