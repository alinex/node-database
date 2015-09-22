chai = require 'chai'
expect = chai.expect

describe "Base", ->

  Database = require '../../src/index'
  config = require 'alinex-config'

#  before (cb) ->
#    @timeout 5000
#    Database.setup ->
#      config.pushOrigin
#        uri: "#{__dirname}/../data/config/database.yml"
#    Database.init cb

  describe "config", ->

    it "should run the selfcheck on the schema", (cb) ->
      validator = require 'alinex-validator'
      schema = require '../../src/configSchema'
      validator.selfcheck schema, cb

    it "should initialize config", (cb) ->
      @timeout 4000
      Exec.init (err) ->
        expect(err, 'init error').to.not.exist
        config = require 'alinex-config'
        config.init (err) ->
          expect(err, 'load error').to.not.exist
          conf = config.get '/exec'
          expect(conf, 'config').to.exist
          expect(conf.retry.error.times, 'retry num').to.be.above -1
          cb()
