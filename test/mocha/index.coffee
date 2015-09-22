chai = require 'chai'
expect = chai.expect

describe "Base", ->

  Database = require '../../src/index'
  config = require 'alinex-config'

  before (cb) ->
    Database.setup ->
      config.pushOrigin
        uri: "#{__dirname}/../data/config/database.yml"
      cb()

  describe "config", ->

    it "should run the selfcheck on the schema", (cb) ->
      validator = require 'alinex-validator'
      schema = require '../../src/configSchema'
      validator.selfcheck schema, cb

    it "should initialize config", (cb) ->
      @timeout 4000
      Database.init (err) ->
        expect(err, 'init error').to.not.exist
        config = require 'alinex-config'
        config.init (err) ->
          expect(err, 'load error').to.not.exist
          conf = config.get '/database'
          expect(conf, 'config').to.exist
          cb()
