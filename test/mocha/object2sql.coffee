chai = require 'chai'
expect = chai.expect


describe.only "object2sql", ->

  object2sql = require '../../src/object2sql'
  driver = new (require '../../src/driver/mysql')

  describe "select", ->

    it "should get all fields", ->
      sql = object2sql
        select: '*'
      , driver
      expect(sql, 'sql').to.equal "SELECT *"

