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

debug = require('debug')('database')
chalk = require 'chalk'
fspath = require 'path'
# include more alinex modules
config = require 'alinex-config'
async = require 'alinex-async'
{object} = require 'alinex-util'
# internal helpers
schema = require './configSchema'

# Setup and Initialization
# -------------------------------------------------

# ### Initialization

# set the modules config paths and validation schema
exports.setup = setup = async.once this, (cb) ->
  # set module search path
  config.register false, fspath.dirname __dirname
  # add schema for module's configuration
  config.setSchema '/database', schema, cb

# set the modules config paths, validation schema and initialize the configuration
exports.init = init = async.once this, (cb) ->
  debug "initialize"
  # set module search path
  setup (err) ->
    return cb err if err
    config.init cb

# Create Instances
# -------------------------------------------------

# ### Factory
# Get an instance for the name. This enables the system to use the same
# Config instance anywhere.
instances = {}
exports.instance = instance = (name, cb) ->
  init (err) ->
    return cb err if err
    # start initializing, if not done
    unless instances[name]?
      return cb new Error "Could not initialize database class without alias." unless name
      debug "create #{name} connection"
      conf = config.get "/database/#{name}"
      return cb new Error "No database for name '#{name}' defined" unless conf?
      # open tunnel
      return tunnel conf, (err, conf) ->
        debug chalk.grey "#{conf.server.type}://#{conf.server.host}:#{conf.server.port}/\
        #{conf.server.database} as #{conf.server.user}"
        # load driver
        try
          Driver = require "./driver/#{conf.server.type}"
        catch err
          return cb new Error "Could not find driver for #{conf.server.type} database:
          #{err.message}"
        instances[name] = new Driver name, conf
        cb null, instances[name]
    cb null, instances[name]

# ### Shutdown
exports.close = close = (cb = -> ) ->
  debug "Close all database connections..."
  async.each Object.keys(instances), (name, cb) ->
    instances[name].close cb
  , cb

tunnel = (conf, cb) ->
  conf.access = conf.server
  return cb null, conf unless conf.ssh
  # load ssh modules
  sshtunnel = require 'alinex-sshtunnel'
  sshtunnel
    ssh: conf.ssh
    tunnel:
      host: conf.server.host
      port: conf.server.port
  , (err, tunnel) ->
    return cb err if err
    conf.access = object.extend {}, conf.server, tunnel.setup
    cb null, conf
