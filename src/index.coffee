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
      # open tunnel
######      tunnel conf, (err, server) ->
      debug chalk.grey "#{conf.server.type}://#{conf.server.host}:#{conf.server.port}/\
      #{conf.server.database} as #{conf.server.user}"
      return cb new Error "No database under the name #{@name} defined." unless conf
      # load driver
      try
        Driver = require "./driver/#{conf.server.type}"
      catch err
        return cb new Error "Could not find driver for #{conf.server.type} database."
      instances[name] = new Driver name, conf
    cb null, instances[name]

# ### Shutdown
exports.close = close = (cb = -> ) ->
  debug "Close all database connections..."
  async.each Object.keys(instances), (name, cb) ->
    instances[name].close cb
  , cb

tunnel = (conf, cb) ->
  return cb null, conf.server unless conf.ssh
  # load ssh modules
  portfinder = require 'portfinder'
  ssh = require 'ssh2'
  # open tunnel
  debug "open ssh tunnel through #{conf.ssh.host}"
  portfinder.getPort (err, port) ->
    return cb err if err
    debug chalk.grey "using 127.0.0.1:#{port} for the tunnel"
    conn = new ssh.Client()
    conn.on 'ready', ->
      console.log '111111111111111'
      conn.forwardOut conf.server.host, conf.server.port, '127.0.0.1', port, (err, stream) ->
        console.log '-------------------------------', err, stream
        return cb err if err
        # new server settings
        #cb null, {}
    conn.connect conf.ssh

# SSH Connections and tunnel
# -------------------------------------------------

# ### Connect to remote server
connect = (host, cb) ->
  conf = config.get 'exec/remote'
  return cb null, pool[host] if pool[host]
  unless host in Object.keys conf.server
    return cb new Error "The remote server '#{host}' is not configured."
  open host, (err, conn) ->
    return cb err if err
    pool[host] = conn
    cb null, conn

# ### Open a new connection
open = (host, cb) ->
  conf = config.get 'exec/remote/server/' + host
  # make new connection
  conn = new ssh.Client()
  conn.name = chalk.grey "ssh://#{conf.username}@#{conf.host}:#{conf.port}"
  debug "#{conn.name} open ssh connection for #{host}"
  conn.on 'ready', ->
    debug chalk.grey "#{conn.name} connection established"
    cb null, conn
  .on 'error', (err) ->
    debug chalk.magenta "#{conn.name} got error: #{err.message}"
  .on 'end', ->
    debug chalk.grey "#{conn.name} connection closed"
  .connect object.extend {}, conf,
    debug: unless conf.debug then null else (msg) ->
      debug chalk.grey "#{conn.name} #{msg}"

# ### Close the connection
close = (host, conn) ->
  delete pool[host]
  conn.end()
