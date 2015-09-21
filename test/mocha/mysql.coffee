chai = require 'chai'
expect = chai.expect
Config = require 'alinex-config'
#require('alinex-error').install()

Mysql = require '../../lib/index'
Config.search.push 'test/data'

describe "Mysql access", ->
  it "simple query to database", (done) ->
    testdb = Mysql.instance 'test'
    testdb.connect (err, conn) ->
      conn.query 'SELECT 2 + 2 AS solution', (err, rows, fields) ->
        throw err if err
        console.log 'The database calculated 2+2: ', rows[0].solution
        conn.release()
        testdb.close (err) ->
          done()

