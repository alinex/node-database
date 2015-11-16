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

# Setup
# -------------------------------------------------
# Return int8 values as integer -> maybe problematic on large values because
# javascript can't handle this.
#pg.setTypeParser 20, (val) ->
#  # remember: all values returned from the server are either NULL or a string
#  return val === null ? null : parseInt val

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
    @connectionNum = 0
    pg.defaults.poolSize = @conf.pool?.limit

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
      application_name: process.title
      fallback_application_name: 'alinex-database'
    , @conf.access
#    console.log 'client', util.inspect client, {depth:null}
    debugPool "#{chalk.grey @name} retrieve connection"
    pg.connect setup, (err, conn, done) =>
      if err
        done()
        err.message += " at #{@name}"
        return cb err
      if conn.alinex?
        debugPool "#{conn.name} reuse connection"
        return cb null, conn
      conn.name = chalk.grey "[#{@name}##{++@connectionNum}]" unless conn.name?
      debugPool "#{conn.name} opened new connection"
      # add debugging
      conn.release = ->
        debugPool "#{conn.name} release connection"
        done()
      query = conn.query
      conn.query = (sql, data, cb) ->
        unless typeof cb is 'function'
          cb = data
          data = null
        data = [data] if typeof data is 'string'
        debugCmd "#{conn.name} #{sql}#{
          if data then chalk.grey(' with ') + util.inspect data else ''
          }"
        if cb
          query.apply conn, [sql, data, (err, result) ->
            if err
              debugResult "#{conn.name} #{chalk.grey err.message}"
            if result.fields.length
              debugResult "#{conn.name} fields: #{util.inspect result.fields}"
            if result.rows.length
              debugData "#{conn.name} #{util.inspect row}" for row in result.rows
#              console.log result
            cb err, result
          ]
          return
        # called using events
        fn = query.apply conn, [sql, data]
        if debugCmd.enabled or debugData.enabled or debugResult.enabled
          fn.on? 'row', (row, result) ->
            debugData "#{conn.name} #{row}"
          fn.on? 'error', (err) ->
            debugResult "#{conn.name} #{chalk.grey err.message}"
          fn.on? 'end', ->
            debugCom chalk.grey "#{conn.name} end query"
        fn
        if debugCom.enabled
          conn.on 'drain', ->
            debugCom chalk.grey "#{conn.name} drained"
          conn.on 'error', (err) ->
            debugCom chalk.magenta "#{conn.name} error: #{err.message}"
          conn.on 'notice', (msg) ->
            debugCom chalk.grey "#{conn.name} notice: #{msg}"
        conn.alinex = true
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
        match = sql.match /\sRETURNING\s+(\S+)/
        lastId = result.rows[0]?[match[1]] if match?[1]?
        cb err, result.rowCount, lastId

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
      conn.query sql, data, (err, result) ->
        conn.release()
        err = new Error "PostgreSQL Error: #{err.message} in #{sql}" if err
        cb err, result?.rows

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
