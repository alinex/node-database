# Mysql access
# =================================================
# This package will give you an easy and robust way to access mysql databases.

# https://github.com/Finanzchef24-GmbH/tunnel-ssh/blob/master/index.js -> copy
# https://github.com/felixge/node-mysql/ -> use
# https://github.com/brianc/node-postgres/tree/master/lib -> use
# https://github.com/mapbox/node-sqlite3 -> use

# Node Modules
# -------------------------------------------------

# include base modules
#debug = require('debug')('db:mysql')
debugPool = require('debug')('db:pool')
debugCmd = require('debug')('db:cmd')
debugResult = require('debug')('db:result')
debugData = require('debug')('db:data')
debugCom = require('debug')('db:com')
chalk = require 'chalk'
util = require 'util'
mysql = require 'mysql'
SqlString = require 'mysql/lib/protocol/SqlString'
# require alinex modules
{object} = require 'alinex-util'
# loading helper modules
object2sql = require '../object2sql'

# Database class
# -------------------------------------------------
class Mysql

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
    # instantiate pool if not already done
    unless @pool?
      debugPool "initialize connection pool for #{@name}"
      setup = object.extend {connectionLimit: @conf.pool?.limit}, @conf.access
      debugPool chalk.grey "set pool limit to #{setup.connectionLimit}" if setup.connectionLimit
      @pool = mysql.createPool setup
      @pool.on 'connection', (conn) =>
        conn.name = chalk.grey "[#{@name}##{conn._socket._handle.fd}]"
        debugPool "#{conn.name} open connection"
        conn.on 'error', (err) ->
          debug "#{conn.name} uncatched #{err} on connection"
      @pool.on 'enqueue', =>
        name = chalk.grey "[#{@name}]"
        debugPool "{@name} waiting for connection"
    # get the connection
    @pool.getConnection (err, conn) =>
      if err
        debugCom chalk.grey("[#{@name}]") + " #{err} while connecting"
        if @tries > 2 # max retries to get a connection
          return cb new Error "#{err.message} while connecting to #{@name} database"
        return setTimeout =>
          @connect cb
        , 1000 # wait a second fbefore retry
      debugPool "#{conn.name} acquired connection"
      # switch on debugging wih own method
      conn.config.debug = true
      conn._protocol._debugPacket = (incoming, packet) ->
        dir = if incoming then '<--' else '-->'
        msg = util.inspect packet
        switch packet.constructor.name
          when 'ComQueryPacket'
            debugCmd "#{conn.name} #{packet.sql}"
          when 'ResultSetHeaderPacket', 'FieldPacket', 'EofPacket'
            debugResult "#{conn.name} #{packet.constructor.name} #{chalk.grey msg}"
          when 'RowDataPacket'
            debugData "#{conn.name} #{msg}"
          when 'ComQuitPacket'
            debugPool "#{conn.name} close connection"
          else
            debugCom "#{conn.name} #{dir} #{packet.constructor.name} #{chalk.grey msg}"
      conn.release = ->
        debugPool "#{conn.name} release connection
        (#{@_pool._freeConnections.length+1}/#{@_pool._allConnections.length} free)"
        # release code copied from original function
        return unless @_pool? and not @_pool._closed
        @_pool.releaseConnection this
      # return the connection
      cb null, conn

  # Shortcut functions
  # -------------------------------------------------

  # ## update, insert or delete something and return count of changes
  exec: (sql, data, cb) ->
    unless typeof cb is 'function'
      cb = data
      data = null
    # replace placeholders
    sql = mysql.format sql, data if data
    # run the query
    @connect (err, conn) ->
      return cb new Error "MySQL Error: #{err.message}" if err
      conn.query sql, (err, result) ->
        conn.release()
        return cb new Error "MySQL Error: #{err.message} in #{sql}" if err
        cb err, result.affectedRows, result.insertId

  # ## get all data as object
  list: (sql, data, cb) ->
    unless typeof cb is 'function'
      cb = data
      data = null
    # replace placeholders
    sql = mysql.format sql, data if data
    # run the query
    @connect (err, conn) ->
      return cb new Error "MySQL Error: #{err.message}" if err
      conn.query sql, (err, result) ->
        conn.release()
        err = new Error "MySQL Error: #{err.message} in #{sql}" if err
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
  escape: SqlString.escape
  escapeId: SqlString.escapeId

  sql: (sql, data) ->
    if typeof sql isnt 'string'
      # object syntax
      sql = object2sql sql, this
    if sql.match /\?(?=([^']*'[^']*')*[^']*$)/
      # placeholder
      return SqlString.format sql, data
    sql

# Exports
# -------------------------------------------------
# The mysql class is exported directly.
module.exports = Mysql
