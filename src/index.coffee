# Mysql access
# =================================================
# This package will give you an easy and robust way to access mysql databases.

# https://github.com/Finanzchef24-GmbH/tunnel-ssh/blob/master/index.js -> copy
# https://github.com/felixge/node-mysql/ -> use
# https://github.com/brianc/node-postgres/tree/master/lib -> use
# https://github.com/mapbox/node-sqlite3 -> use
# https://github.com/elastic/elasticsearch-js

# https://www.npmjs.com/package/json-sql

# Node Modules
# -------------------------------------------------

debug = require('debug')('db')
chalk = require 'chalk'
fspath = require 'path'
# include more alinex modules
config = require 'alinex-config'
async = require 'alinex-async'
# internal helpers
schema = require './configSchema'

# Class definition
# -------------------------------------------------
class Database

  # ### Initialization

  # set the modules config paths and validation schema
  @setup: async.once this, (cb) ->
    # set module search path
    config.register false, fspath.dirname __dirname
    # add schema for module's configuration
    config.setSchema '/database', schema, cb

  # set the modules config paths, validation schema and initialize the configuration
  @init: async.once this, (cb) ->
    debug "initialize"
    # set module search path
    @setup (err) ->
      return cb err if err
      config.init cb

  # ### Shutdown
  @close: (cb = -> ) ->
    debug "Close all database connections..."
    async.each Object.keys(@_instances), (name, cb) =>
      @_instances[name].close cb
    , cb

  # ### Factory
  # Get an instance for the name. This enables the system to use the same
  # Config instance anywhere.
  @_instances: {}
  @instance: (name) ->
    # start initializing, if not done
    unless @_instances[name]?
      debugPool "create new pool for #{name}"
      @_instances[name] = new Database name
    @_instances[name]

  # Instance Methods
  # -------------------------------------------------

  # ### Create instance
  # This will also load the data if not already done. Don't call this directly
  # better use the `instance()` method which implements the factory pattern.
  constructor: (@name) ->
    debug "create #{@name} instance"
    @conf = config.get "/database/#{@name}"
    throw new Error "Could not initialize database class without alias." unless @name
    throw new Error "No database under the name #{@name} defined." unless @conf
    # load module
    try
      @driver = require "./driver/#{@conf.server.type}"
    catch err
      throw new Error "Could not find driver for #{@conf.server.type} database."

  # ### Close connection pool
  close: (cb = -> ) ->
    debugPool "close connection pool for #{@name}"
    return cb() unless @pool?
    @pool.end (err) =>
      # remove pool instance to be reopened on next use
      @pool = null
      cb err

  # ### Get connection
  connect: (cb) ->
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
          conn.on 'error', (err) ->
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
          debugPool "#{conn.name} release connection
          (#{@_pool._freeConnections.length+1}/#{@_pool._allConnections.length} free)"
          # release code copied from original function
          return unless @_pool? and not @_pool._closed
          @_pool.releaseConnection this
        # return the connection
        cb null, conn

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


# Exports
# -------------------------------------------------
# The mysql class is exported directly.
module.exports = Database
