# Mysql access
# =================================================
# This package will give you an easy and robust way to access mysql databases.

# Node Modules
# -------------------------------------------------

# include base modules
#debug = require('debug')('db:mysql')
debugPool = require('debug')('database:pool')
debugCmd = require('debug')('database:cmd')
debugResult = require('debug')('database:result')
debugData = require('debug')('database:data')
debugCom = require('debug')('database:com')
debugError = require('debug')('database:error')
chalk = require 'chalk'
mysql = require 'mysql'
SqlString = require 'mysql/lib/protocol/SqlString'
# require alinex modules
util = require 'alinex-util'
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
    debugPool "close connection pool for #{@name}" if debugPool.enabled
    @pool.end (err) =>
      # remove pool instance to be reopened on next use
      @pool = null
      cb err

  # ### Get connection
  connect: (cb) ->
    # instantiate pool if not already done
    unless @pool?
      debugPool "initialize connection pool for #{@name}" if debugPool.enabled
      setup = util.extend
        connectionLimit: @conf.pool?.limit
        multipleStatements: true
      , @conf.access
      if debugPool.enabled and setup.connectionLimit
        debugPool chalk.grey "set pool limit to #{setup.connectionLimit}"
      @pool = mysql.createPool setup
      @pool.on 'connection', (conn) =>
        conn.name = chalk.grey "[#{@name}##{conn._socket._handle.fd}]"
        debugPool "#{conn.name} open connection" if debugPool.enabled
        conn.on 'error', (err) ->
          debugError "#{conn.name} uncatched #{err} on connection" if debugError.enabled
      @pool.on 'enqueue', =>
        name = chalk.grey "[#{@name}]"
        debugPool "#{name} waiting for connection" if debugPool.enabled
    # get the connection
    @pool.getConnection (err, conn) =>
      if err
        debugError chalk.grey("[#{@name}]") + " #{err} while connecting" if debugError.enabled
        if @tries > 2 # max retries to get a connection
          return cb new Error "#{err.message} while connecting to #{@name} database"
        return setTimeout =>
          @connect cb
        , 1000 # wait a second fbefore retry
      debugPool "#{conn.name} acquired connection" if debugPool.enabled
      # switch on debugging wih own method
      conn.config.debug = true
      conn._protocol._debugPacket = (incoming, packet) ->
        dir = if incoming then '<--' else '-->'
        msg = util.inspect packet
        switch packet.constructor.name
          when 'ComQueryPacket'
            debugCmd "#{conn.name} #{packet.sql}" if debugCmd.enabled
          when 'ResultSetHeaderPacket', 'FieldPacket', 'EofPacket'
            if debugResult.enabled
              debugResult "#{conn.name} #{packet.constructor.name} #{chalk.grey msg}"
          when 'RowDataPacket'
            debugData "#{conn.name} #{msg}" if debugData.enabled
          when 'ComQuitPacket'
            debugPool "#{conn.name} close connection" if debugPool.enabled
          else
            if debugCom.enabled
              debugCom "#{conn.name} #{dir} #{packet.constructor.name} #{chalk.grey msg}"
      conn.release = ->
        if debugPool.enabled
          debugPool "#{conn.name} release connection
          (#{@_pool._freeConnections.length+1}/#{@_pool._allConnections.length} free)"
        # release code copied from original function
        return unless @_pool? and not @_pool._closed
        @_pool.releaseConnection this
      # return the connection
      cb null, conn

  # Shortcut functions
  # -------------------------------------------------

  # ### update, insert or delete something and return count of changes
  exec: -> @prepare arguments, (err, conn, sql, data, cb) =>
    return cb err if err
    # run the query
    @query conn, sql, data, (err, result) ->
      cb err, result?.affectedRows, result?.insertId

  # ### get all data as object
  list: -> @prepare arguments, (err, conn, sql, data, cb) =>
    return cb err if err
    # run the query
    @query conn, sql, data, cb

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
      return cb() unless result?.length
      cb err, result[0]

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
      return cb() unless result?.length
      cb err, result[0][Object.keys(result[0])[0]]

  # ### get value of one field
  column: -> @prepare arguments, (err, conn, sql, data, cb) =>
    return cb err if err
    # run the query
    @query conn, sql, data, (err, result) ->
      return cb err if err
      return cb() unless result?.length
      cb err, result.map (e) -> e[Object.keys(e)[0]]

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
        return cb new Error "MySQL Error: #{err.message}" if err
        conn.release()
        done.apply this, arguments

  # ### Run the query on the wrapped driver
  query: (conn, sql, data, cb) ->
    # replace placeholder and interpret object structure
    sql = @sql sql, data
    # run the query
    conn.query sql, data, (err, result) ->
      return cb new Error "MySQL Error: #{err.message} in #{sql}" if err
      cb null, result

  # Query creation
  # -------------------------------------------------
  escape: SqlString.escape
  escapeId: SqlString.escapeId

  # ### Replace placeholder and object structure
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
