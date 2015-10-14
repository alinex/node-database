chai = require 'chai'
expect = chai.expect


describe "mysql object", ->

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
        from: '@person'
      , "SELECT * FROM `person`"
    it "should get all fields from table", ->
      test
        select: '@person.*'
        from: '@person'
      , "SELECT `person`.* FROM `person`"
    it "should get multiple fields", ->
      test
        select: ['@name', '@age']
        from: '@person'
      , "SELECT `name`, `age` FROM `person`"
    it "should get fields with alias", ->
      test
        select:
          Name: '@name'
          Age: '@age'
        from: '@person'
      , "SELECT `name` AS `Name`, `age` AS `Age` FROM `person`"
    it "should read multiple tables", ->
      test
        select: '*'
        from: ['@person', '@address']
      , "SELECT * FROM `person`, `address`"
    it "should allow table alias", ->
      test
        select: '*'
        from:
          p: '@person'
          a: '@address'
      , "SELECT * FROM `person` AS `p`, `address` AS `a`"

