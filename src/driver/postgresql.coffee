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
    pool = pg.pools.getOrCreate setup
    debugPool "#{chalk.grey @name} retrieve connection" +
      chalk.grey " (pool #{pool.availableObjectsCount()}/#{pool.getPoolSize()})"
    pg.connect setup, (err, conn, done) =>
      if err
        done err
        debugPool "#{conn.name} error #{err.message}"
        err.message += " at #{@name}"
        return cb err
      if conn.alinex?
        debugPool "#{conn.name} reuse connection" +
          chalk.grey " (pool #{pool.availableObjectsCount()}/#{pool.getPoolSize()})"
        return cb null, conn
      conn.name = chalk.grey "[#{@name}##{++@connectionNum}]" unless conn.name?
      debugPool "#{conn.name} opened new connection" +
        chalk.grey " (pool #{pool.availableObjectsCount()}/#{pool.getPoolSize()})"
      # add debugging
      conn.release = ->
        done()
        debugPool "#{conn.name} release connection" +
          chalk.grey " (pool #{pool.availableObjectsCount()}/#{pool.getPoolSize()})"
      conn.on 'error', (err) ->
        done err
        debugPool "#{conn.name} failure #{err.message}"
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
            if result?
              if result.fields.length
                debugResult "#{conn.name} fields: #{util.inspect result.fields}"
              if result.rows.length
                debugData "#{conn.name} #{util.inspect row}" for row in result.rows
#              console.log result
            cb err, result
          ]
          conn.alinex = true
          return
        # called using events
        fn = query.apply conn, [sql, data]
        if debugCmd.enabled or debugData.enabled or debugResult.enabled
          fn.on? 'row', (row) ->
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

  # ### update, insert or delete something and return count of changes
  exec: -> @prepare arguments, (err, conn, sql, data, cb) =>
    return cb err if err
    # run the query
    @query conn, sql, data, (err, result) ->
      return cb err if err
      match = sql.match /\sRETURNING\s+(\S+)/
      lastId = result.rows[0]?[match[1]] if match?[1]?
      cb err, result.rowCount, lastId

  # ### get all data as object
  list: -> @prepare arguments, (err, conn, sql, data, cb) =>
    return cb err if err
    # run the query
    @query conn, sql, data, (err, result) ->
      cb err, result?.rows

  # ### get one record as object
  record: -> @prepare arguments, (err, conn, sql, data, cb) =>
    return cb err if err
    # get only one row
    if typeof sql is 'object'
      sql.limit = 1
    else unless sql.match /\slimit\s+\d/i
      sql += " LIMIT 1"
    # run the query
    @query conn, sql, data, (err, result) ->
      return cb err if err
      rows = result.rows
      return cb() unless rows.length
      # parse result
      cb err, rows[0]

  # ### get value of one field
  value: -> @prepare arguments, (err, conn, sql, data, cb) =>
    return cb err if err
    # get only one row
    if typeof sql is 'object'
      sql.limit = 1
    else unless sql.match /\slimit\s+\d/i
      sql += " LIMIT 1"
    # run the query
    @query conn, sql, data, (err, result) ->
      return cb err if err
      rows = result.rows
      return cb() unless rows.length
      # parse result
      cb err, rows[0][Object.keys(rows[0])[0]]

  # ### get value of one field
  column: -> @prepare arguments, (err, conn, sql, data, cb) =>
    return cb err if err
    # run the query
    @query conn, sql, data, (err, result) ->
      return cb err if err
      rows = result.rows
      return cb() unless rows.length
      # parse result
      cb err, rows.map (e) -> e[Object.keys(e)[0]]

  # Query helper
  # -------------------------------------------------

  # ### prepare parameter
  # This will also open a self closing connection if none given.
  prepare: (args, cb) ->
    args = Array.prototype.slice.call args
    # defaultd
    conn = null
    done = ->
    if typeof args[0] is 'object' and args[0].constructor.name isnt 'Object'
      conn = args.shift()
    last = args.length - 1
    if typeof args[last] is 'function'
      done = args.pop()
    [sql, data] = args
    return cb null, conn, sql, data, done if conn
    @connect (err, conn) ->
      cb err, conn, sql, data, (err) ->
        return done new Error "PostgreSQL Error: #{err.message}" if err
        conn.release()
        done.apply this, arguments

  # ### Run the query on the wrapped driver
  query: (conn, sql, data, cb) ->
    # replace placeholder and interpret object structure
    sql = @sql sql, data
    # run the query
    conn.query sql, data, (err, result) ->
      return cb new Error "PostgreSQL Error: #{err.message} in #{sql}" if err
      cb null, result

  # Query creation
  # -------------------------------------------------
  escape: ->#SqlString.escape
  escapeId: ->#SqlString.escapeId

  sql: (sql) ->
    if typeof sql isnt 'string'
      # object syntax
      sql = object2sql sql, this
#    if sql.match /\?(?=([^']*'[^']*')*[^']*$)/
    # replace ? with $1...
    num = 0
    sql.replace /\?(?=([^']*'[^']*')*[^']*$)/g, -> "$#{++num}"


# Exports
# -------------------------------------------------
# The postgresql class is exported directly.
module.exports = Postgresql
