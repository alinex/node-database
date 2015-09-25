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

  # ### Factory
  # Get an instance for the name. This enables the system to use the same
  # Config instance anywhere.
  @_instances: {}
  @instance: (name) ->
    # start initializing, if not done
    unless @_instances[name]?
      @_instances[name] = new Mysql name
    @_instances[name]

  @close: (cb = -> ) ->
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
      throw new Error "Could not initialize database class without alias."


# Exports
# -------------------------------------------------
# The mysql class is exported directly.
module.exports = Database
