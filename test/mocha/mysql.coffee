chai = require 'chai'
expect = chai.expect
Config = require 'alinex-config'
#require('alinex-error').install()

Database = require '../../src/index'

describe "Mysql access", ->

  it "simple query to database", (done) ->
    db = Database.instance 'test-mysql'
    db.connect (err, conn) ->
      conn.query 'SELECT 2 + 2 AS solution', (err, rows, fields) ->
        throw err if err
        console.log 'The database calculated 2+2: ', rows[0].solution
        conn.release()
        db.close (err) ->
          done()

