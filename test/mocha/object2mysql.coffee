chai = require 'chai'
expect = chai.expect


describe.only "object to mysql", ->

  Driver = require '../../src/driver/mysql'
  object2sql = require '../../src/object2sql'
  driver = new Driver 'mocha',
    server:
      type: 'mysql'

  test = (obj, check) ->
    sql = object2sql obj, driver
    expect(sql, 'created sql').to.equal check

  describe "select", ->

    it "should get all fields", ->
      test
        select: '*'
        from: 'person'
      , "SELECT * FROM `person`"
    it "should get all fields from table", ->
      test
        select: 'person.*'
      , "SELECT `person`.*"
    it "should get multiple fields", ->
      test
        select: ['name', 'age']
      , "SELECT `name`, `age`"
    it "should get fields with alias", ->
      test
        select:
          Name: 'name'
          Age: 'age'
      , "SELECT `name` AS `Name`, `age` AS `Age`"

