###
Database Access - API Usage
=================================================
###


# https://github.com/Finanzchef24-GmbH/tunnel-ssh/blob/master/index.js -> copy
# https://github.com/felixge/node-mysql/ -> use
# https://github.com/brianc/node-postgres/tree/master/lib -> use
# https://github.com/mapbox/node-sqlite3 -> use
# https://github.com/elastic/elasticsearch-js

# https://www.npmjs.com/package/json-sql

# Node Modules
# -------------------------------------------------

debug = require('debug')('database')
chalk = require 'chalk'
async = require 'async'
fspath = require 'path'
# include more alinex modules
config = require 'alinex-config'
util = require 'alinex-util'
ssh = null # load on demand
# internal helpers
schema = require './configSchema'


# Setup and Initialization
# -------------------------------------------------

###
set the modules config paths and validation schema

@param {Function(Error)} cb callback after done
###
exports.setup = setup = util.function.once this, (cb) ->
  # set module search path
  config.register false, fspath.dirname __dirname
  # add schema for module's configuration
  config.setSchema '/database', schema, cb

###
set the modules config paths, validation schema and initialize the configuration

@param {Function(Error)} cb callback after done
###
exports.init = init = util.function.once this, (cb) ->
  debug "initialize"
  # set module search path
  setup (err) ->
    return cb err if err
    config.init cb


# Create Instances
# -------------------------------------------------

# @type {Object<Database>} named list of database connections
#
instances = {}

# Get an instance for the name. This enables the system to use the same
# database instance anywhere.
#
# @param {String} name the alias for the database connection configuration
# @param {Function(Error, Database)} cb with an `Error` or the `Database` instance
exports.instance = instance = (name, cb) ->
  init (err) ->
    return cb err if err
    # start initializing, if not done
    unless instances[name]?
      return cb new Error "Could not initialize database class without alias." unless name
      debug "create #{name} connection" if debug.enabled
      conf = config.get "/database/#{name}"
      return cb new Error "No database for name '#{name}' defined" unless conf?
      # open tunnel
      return tunnel conf, (err, conf) ->
        return cb err if err
        debug chalk.grey "#{conf.server.type}://#{conf.server.host}:#{conf.server.port}/\
        #{conf.server.database} as #{conf.server.user}" if debug.enabled
        # load driver
        try
          Driver = require "./driver/#{conf.server.type}"
        catch error
          return cb new Error "Could not find driver for #{conf.server.type} database:
          #{error.message}"
        instances[name] = new Driver name, conf
        cb null, instances[name]
    cb null, instances[name]



#for fn in ['exec', 'list', 'record', 'column', 'value']
#  exports[fn] = (name, query, data, cb) -> call fn, name, query, data, cb
exports.exec = (name, query, data, cb) -> call 'exec', name, query, data, cb
exports.list = (name, query, data, cb) -> call 'list', name, query, data, cb
exports.record = (name, query, data, cb) -> call 'record', name, query, data, cb
exports.column = (name, query, data, cb) -> call 'column', name, query, data, cb
exports.value = (name, query, data, cb) -> call 'value', name, query, data, cb

call = (fn, name, query, data, cb) ->
  unless typeof cb is 'function'
    cb = data
    data = null
  instance name, (err, db) ->
    return cb err if err
    unless db[fn]?
      return cb new Error "The #{db.constructor.name} driver didn't support the #{fn}() method."
    db[fn] query, data, cb

# ### Shutdown
exports.close = (cb = -> ) ->
  debug "Close all database connections..."
  async.each Object.keys(instances), (name, cb) ->
    instances[name].close cb
  , cb

# ### Open SSH Tunnel if needed
tunnel = (conf, cb) ->
  conf.access = conf.server
  return cb null, conf unless conf.ssh
  # load ssh modules
  ssh ?= require 'alinex-ssh'
  ssh.tunnel
    server: conf.ssh
    tunnel:
      host: conf.server.host
      port: conf.server.port
  , (err, tunnel) ->
    return cb err if err
    conf.access = util.extend 'MODE CLONE', conf.server, tunnel.setup
    cb null, conf
