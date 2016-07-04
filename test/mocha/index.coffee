chai = require 'chai'
expect = chai.expect
### eslint-env node, mocha ###

database = require '../../src/index'
config = require 'alinex-config'
database.setup ->
  config.pushOrigin
    uri: "#{__dirname}/../data/config/database.yml"

describe "Base", ->

  describe "config", ->

    it "should run the selfcheck on the schema", (cb) ->
      validator = require 'alinex-validator'
      schema = require '../../src/configSchema'
      validator.selfcheck schema, cb

    it "should initialize config", (cb) ->
      @timeout 4000
      database.init (err) ->
        expect(err, 'init error').to.not.exist
        config = require 'alinex-config'
        config.init (err) ->
          expect(err, 'load error').to.not.exist
          conf = config.get '/database'
          expect(conf, 'config').to.exist
          cb()

    it "should throw error if no database defined", (cb) ->
      @timeout 4000
      database.instance 'not-existent-db', (err) ->
        expect(err, 'config error').to.exist
        cb()

  describe.skip "connect problems", ->

    it "should allow connections to database", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.connect (err, conn) ->
          expect(err, 'error on connection').to.not.exist
          conn.query 'SELECT 2 + 2 AS solution', (err, rows) ->
            throw err if err
            console.log 'The database calculated 2+2 =', rows[0].solution
            conn.release()
            db.close done
