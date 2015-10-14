chai = require 'chai'
expect = chai.expect


describe "Mysql object", ->

  Driver = require '../../src/driver/mysql'
  object2sql = require '../../src/object2sql'
  driver = new Driver 'mocha',
    server:
      type: 'mysql'

  test = (obj, check) ->
    sql = object2sql obj, driver
    expect(sql, 'created sql').to.equal check

  describe "SELECT", ->

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


  describe "FROM", ->

    it "should use one table", ->
      test
        select: '*'
        from: '@person'
      , "SELECT * FROM `person`"
    it "should use multiple tables", ->
      test
        select: '*'
        from: ['@person', '@address']
      , "SELECT * FROM `person`, `address`"
    it "should support alias", ->
      test
        select: '*'
        from:
          Person: '@person'
      , "SELECT * FROM `person` AS `Person`"
    it "should support left join", ->
      test
        select: '*'
        from:
          Person: '@person'
          Address:
            address:
              join: 'left'   # left, right, outer, inner
              on:            # join criteria
                ID: '@Person.addressID'
      , "SELECT * FROM `person` AS `Person` LEFT JOIN `address` AS `Address` ON `Address`.`ID` = `Person`.`addressID`"
    it "should support join in array", ->
      test
        select: '*'
        from: [
          Person: '@person'
        ,
          Address:
            address:
              join: 'left'   # left, right, outer, inner
              on:            # join criteria
                ID: '@Person.addressID'
        ]
      , "SELECT * FROM `person` AS `Person` LEFT JOIN `address` AS `Address` ON `Address`.`ID` = `Person`.`addressID`"


  describe "placeholder", ->
