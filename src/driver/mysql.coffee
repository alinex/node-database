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
debug = require('debug')('mysql')
debugPool = require('debug')('mysql:pool')
debugQuery = require('debug')('mysql:query')
debugResult = require('debug')('mysql:result')
debugData = require('debug')('mysql:data')
debugCom = require('debug')('mysql:com')
chalk = require 'chalk'
util = require 'util'
path = require 'path'
mysql = require 'mysql'
SqlString = require 'mysql/lib/protocol/SqlString'
async = require 'alinex-async'

# Database class
# -------------------------------------------------
class Mysql

  # sql creation helpers
  @escape: SqlString.escape
  @escapeId: SqlString.escapeId
  @format: SqlString.format

  @init: async.once (@config = 'mysql', cb) =>
    # start new initialization if not running
    debug "init or reinit mysql"
    # set config from different values
    if typeof @config is 'string'
      @config = Config.instance @config
      # add the module's directory as default
      @config.search.unshift path.resolve path.dirname(__dirname), 'var/src/config'
      # add the check methods
      @config.setCheck configcheck
    if @config instanceof Config
      @configClass = @config
      @config = @configClass.data
    # set init status if configuration is loaded
    return cb() unless @configClass?
    # wait till configuration is loaded
    @configClass.load (err) =>
      console.error err if err
      cb err

  # ### Factory
  # Get an instance for the name. This enables the system to use the same
  # Config instance anywhere.
  @_instances: {}
  @instance: (name) ->
    # start initializing, if not done
    unless @_instances[name]?
      @_instances[name] = new Mysql name
    @_instances[name]

  @close: (cb = ->) ->
    debug "Close all database connections..."
    async.each Object.keys(@_instances), (name, cb) =>
      @_instances[name].close cb
    , cb

  # ### Create instance
  # This will also load the data if not already done. Don't call this directly
  # better use the `instance()` method which implements the factory pattern.
  constructor: (@name) ->
    debug "create #{@name} instance"
    unless @name
      throw new Error "Could not initialize Mysql class without database alias."

  connect: (cb, num=0) ->
    Mysql.init null, (err) =>
      return cb err if err
      # instantiate pool if not already done
      unless @pool?
        debugPool "initialize connection pool for #{@name}"
        unless @constructor.config[@name]
          return cb new Error "Given database alias '#{@name}' is not defined in configuration."
        @pool = mysql.createPool @constructor.config[@name]
        @pool.on 'connection', (conn) =>
          conn.name = chalk.grey "[#{@name}##{conn._socket._handle.fd}]"
          debugPool "#{conn.name} open connection"
          conn.on 'error', (err) =>
            debug "#{conn.name} uncatched #{err} on connection"
        @pool.on 'enqueue', =>
          name = chalk.grey "[#{@name}]"
          debugPool "{@name} waiting for connection"
      # get the connection
      @pool.getConnection (err, conn) =>
        if err
          debug chalk.grey("[#{@name}]") + " #{err} while connecting"
          if num > 10 # max retries to get a connection
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
              debugQuery "#{conn.name} #{packet.sql}"
            when 'ResultSetHeaderPacket', 'FieldPacket', 'EofPacket'
              debugResult "#{conn.name} #{packet.constructor.name} #{chalk.grey msg}"
            when 'RowDataPacket'
              debugData "#{conn.name} #{msg}"
            when 'ComQuitPacket'
              debugPool "#{conn.name} close connection"
            else
              debugCom "#{conn.name} #{dir} #{packet.constructor.name} #{chalk.grey msg}"
        conn.release = ->
          debugPool "#{conn.name} release connection (#{@_pool._freeConnections.length+1}/#{@_pool._allConnections.length} free)"
          # release code copied from original function
          return unless @_pool? and not @_pool._closed
          @_pool.releaseConnection @
        # return the connection
        cb null, conn

  close: (cb = ->) =>
    debugPool "close connection pool for #{@name}"
    return cb() unless @pool?
    @pool.end (err) =>
      # remove pool instance to be reopened on next use
      @pool = null
      cb err

  # Shortcut functions
  # -------------------------------------------------

  # ## get all data as object
  query: (sql, data, cb) ->
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

  # ## get value of one field
  queryOne: (sql, data, cb) ->
    unless typeof cb is 'function'
      cb = data
      data = null
    @query sql, data, (err, result) ->
      return cb err if err
      return cb() unless result?.length
      unless result[0]? or Object.keys result[0]
        cb err, null
      cb err, result[0][Object.keys(result[0])]

  # ## get one record as object
  queryRow: (sql, data, cb) ->
    unless typeof cb is 'function'
      cb = data
      data = null
    @query sql, data, (err, result) ->
      return cb err if err
      return cb() unless result?.length
      unless result[0]? or Object.keys result[0]
        cb err, null
      cb err, result[0]

  # ## get number of records found
  queryCount: (sql, data, cb) ->
    unless typeof cb is 'function'
      cb = data
      data = null
    @query sql, data, (err, result) ->
      return cb err if err
      return cb null, result?.length

  # ## update, insert or delete something and return count of changes
  update: (sql, data, cb) ->
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
        cb err, result.affectedRows

  # ## insert record and return new primary key
  insertId: (sql, data, cb) ->
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
        cb err, result.insertId


# Exports
# -------------------------------------------------
# The mysql class is exported directly.
module.exports = Mysql
