# PostgreSQL access
# =================================================
# This package will give you an easy and robust way to access PostgreSQL databases.

# Node Modules
# -------------------------------------------------

# include base modules
debugPool = require('debug')('database:pool')
debugCmd = require('debug')('database:cmd')
debugResult = require('debug')('database:result')
debugData = require('debug')('database:data')
debugCom = require('debug')('database:com')
chalk = require 'chalk'
util = require 'util'
pg = require 'pg'
# require alinex modules
{object} = require 'alinex-util'
# loading helper modules
object2sql = require '../object2sql'

# Database class
# -------------------------------------------------
class Postgresql

  # Connection handling
  # -------------------------------------------------

  # ### Create instance
  # This will also load the data if not already done. Don't call this directly
  # better use the `instance()` method which implements the factory pattern.
  constructor: (@name, @conf) ->
    @tries = 0

  close: (cb = -> ) ->
    return cb() unless @pool?
    debugPool "close connection pool for #{@name}"
    @pool.end (err) =>
      # remove pool instance to be reopened on next use
      @pool = null
      cb err

  # ### Get connection
  connect: (cb) ->
    setup = object.extend
#      connectionLimit: @conf.pool?.limit
      application_name: process.title
      fallback_application_name: 'alinex-database'
    , @conf.access
#    console.log 'client', util.inspect client, {depth:null}
    debugPool "#{chalk.grey @name} retrieve connection"
    pg.connect setup, (err, conn, done) =>
      if err
        done()
        return cb err
      conn.name = chalk.grey "[#{@name}]"
      conn.release = ->
        debugPool "#{conn.name} release connection"
        done()
      cb null, conn

  # Shortcut functions
  # -------------------------------------------------

  # ## update, insert or delete something and return count of changes
  exec: (sql, data, cb) ->
    unless typeof cb is 'function'
      cb = data
      data = null
    # replace placeholders
    sql = @sql sql, data
    # run the query
    @connect (err, conn) ->
      return cb new Error "PostgreSQL Error: #{err.message}" if err
      conn.query sql, (err, result) ->
        conn.release()
        return cb new Error "PostgreSQL Error: #{err.message} in #{sql}" if err
        console.log result
        cb err, result.affectedRows, result.insertId

  # ## get all data as object
  list: (sql, data, cb) ->
    unless typeof cb is 'function'
      cb = data
      data = null
    # replace placeholders
    sql = @sql sql, data
    # run the query
    @connect (err, conn) ->
      return cb new Error "PostgreSQL Error: #{err.message}" if err
      conn.query sql, (err, result) ->
        conn.release()
        err = new Error "PostgreSQL Error: #{err.message} in #{sql}" if err
        cb err, result

  # ## get one record as object
  record: (sql, data, cb) ->
    unless typeof cb is 'function'
      cb = data
      data = null
    ######### add LIMIT 1 through json
    @list sql, data, (err, result) ->
      return cb err if err
      return cb() unless result?.length
      unless result[0]? or Object.keys result[0]
        cb err, null
      cb err, result[0]

  # ## get value of one field
  value: (sql, data, cb) ->
    unless typeof cb is 'function'
      cb = data
      data = null
    ######### add LIMIT 1 through json
    @list sql, data, (err, result) ->
      return cb err if err
      return cb() unless result?.length
      unless result[0]? or Object.keys result[0]
        cb err, null
      cb err, result[0][Object.keys(result[0])]

  # ## get value of one field
  column: (sql, data, cb) ->
    unless typeof cb is 'function'
      cb = data
      data = null
    ######### add LIMIT 1 through json
    @list sql, data, (err, result) ->
      return cb err if err
      return cb() unless result?.length
      unless result[0]? or Object.keys result[0]
        cb err, null
      cb err, result.map (e) -> e[Object.keys(e)[0]]

  # Query creation
  # -------------------------------------------------
  escape: ->#SqlString.escape
  escapeId: ->#SqlString.escapeId

  sql: (sql, data) ->
    if typeof sql isnt 'string'
      # object syntax
      sql = object2sql sql, this
    if sql.match /\?(?=([^']*'[^']*')*[^']*$)/
      # placeholder
      return #SqlString.format sql, data
    sql



# Exports
# -------------------------------------------------
# The postgresql class is exported directly.
module.exports = Postgresql
