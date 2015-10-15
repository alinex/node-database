chai = require 'chai'
expect = chai.expect

database = require '../../src/index'
async = require 'alinex-async'
{string} = require 'alinex-util'

describe "Mysql object", ->

  Driver = require '../../src/driver/mysql'
  object2sql = require '../../src/object2sql'
  driver = new Driver 'mocha',
    server:
      type: 'mysql'

  example =
    person:
      struct:
        id: 'INT AUTO_INCREMENT PRIMARY KEY'
        name: 'VARCHAR(10)'
        age: 'INT'
        comment: 'VARCHAR(32)'
      data: [
        id: 1
        age: 30
        name: "Alf"
        comment: null
      ,
        id: 2
        name: "Egon"
        age: 35
        comment: null
      ]
    address:
      struct:
        id: 'INT AUTO_INCREMENT PRIMARY KEY'
        person_id: 'INT'
        city: 'VARCHAR(20)'
      data: [
        id: 1
        person_id: 1
        city: 'Munich'
      ,
        id: 2
        person_id: 1
        city: 'New York'
      ]

  before (done) ->
    database.instance 'test-mysql', (err, db) ->
      throw err if err
      queries = []
      for table in Object.keys example
        fields = Object.keys(example[table].struct).map (e) -> "#{e} #{example[table].struct[e]}"
        .join ', '
        queries.push "CREATE TABLE #{table} (#{fields})"
      for e in example[table].data
        queries.push "INSERT INTO #{table} SET " +  (
          Object.keys(e).map (k) ->
            "#{k} = " + switch
              when not e[k]?
                'NULL'
              when typeof e[k] is 'number'
                e[k]
              else
                "'#{e[k]}'"
          .join ', '
        )
      async.eachSeries queries, (sql, cb) ->
        db.exec sql, cb
      , (err) ->
        expect(err, 'error on init data').to.not.exist
        db.close done

  after (done) ->
    database.instance 'test-mysql', (err, db) ->
      throw err if err
      async.eachSeries Object.keys(example), (table, cb) ->
        db.exec "DROP TABLE IF EXISTS #{table}", cb
      , (err) ->
        expect(err, 'error after drop').to.not.exist
        db.close done

  list = (obj, data, sql, check, cb) ->
    database.instance 'test-mysql', (err, db) ->
      throw err if err
      expect(object2sql(obj, db), 'sql').to.equal sql
      db.list obj, data, (err, res) ->
        expect(err, 'server error').to.not.exist
        expect(res, 'result').to.deep.equal check
        cb()

  record = (obj, data, sql, check, cb) ->
    database.instance 'test-mysql', (err, db) ->
      throw err if err
      expect(object2sql(obj, db), 'sql').to.equal sql
      db.record obj, data, (err, res) ->
        expect(err, 'server error').to.not.exist
        expect(res, 'result').to.deep.equal check
        cb()

  value = (obj, data, sql, check, cb) ->
    database.instance 'test-mysql', (err, db) ->
      throw err if err
      expect(object2sql(obj, db), 'sql').to.equal sql
      db.value obj, data, (err, res) ->
        expect(err, 'server error').to.not.exist
        expect(res, 'result').to.deep.equal check
        cb()

  describe "SELECT", ->

    it "should get all fields", (cb) ->
      list
        select: '*'
        from: '@person'
      , null
      , "SELECT * FROM `person`"
      , example.person.data
      , cb
    it "should get all fields from table", (cb) ->
      list
        select: '@person.*'
        from: '@person'
      , null
      , "SELECT `person`.* FROM `person`"
      , example.person.data
      , cb
    it "should get multiple fields", (cb) ->
      list
        select: ['@name', '@age']
        from: '@person'
      , null
      , "SELECT `name`, `age` FROM `person`"
      , example.person.data.map((e) ->
          n = {}
          for k, v of e
            n[k] = v if k in ['name', 'age']
          n
        )
      , cb
    it "should get fields with alias", (cb) ->
      list
        select:
          Name: '@name'
          Age: '@age'
        from: '@person'
      , null
      , "SELECT `name` AS `Name`, `age` AS `Age` FROM `person`"
      , example.person.data.map((e) ->
          n = {}
          for k, v of e
            n[string.ucFirst k] = v if k in ['name', 'age']
          n
        )
      , cb
    it "should read multiple tables", (cb) ->
      list
        select: '*'
        from: ['@person', '@address']
      , null
      , "SELECT * FROM `person`, `address`"
      , example.person.data
      , cb
    it "should allow table alias", (cb) ->
      test
        select: '*'
        from:
          p: '@person'
          a: '@address'
      , null
      , "SELECT * FROM `person` AS `p`, `address` AS `a`"
      , example.person.data.map((e) ->
          n = {}
          for k, v of e
            n[k] = v if k in ['name', 'age']
          n
        )
      , cb


  describe "FROM", ->

    it "should use one table", (cb) ->
      list
        select: '*'
        from: '@person'
      , null
      , "SELECT * FROM `person`"
      , [{}]
      , cb
    it "should use multiple tables", (cb) ->
      list
        select: '*'
        from: ['@person', '@address']
      , null
      , "SELECT * FROM `person`, `address`"
      , [{}]
      , cb
    it "should support alias", (cb) ->
      list
        select: '*'
        from:
          Person: '@person'
      , null
      , "SELECT * FROM `person` AS `Person`"
      , [{}]
      , cb
    it "should support left join", (cb) ->
      list
        select: '*'
        from:
          Person: '@person'
          Address:
            address:
              join: 'left'   # left, right, outer, inner
              on:            # join criteria
                ID: '@Person.addressID'
      , null
      , "SELECT * FROM `person` AS `Person` LEFT JOIN `address` AS `Address` ON `Address`.`ID` = `Person`.`addressID`"
      , [{}]
      , cb
    it "should support join in array", (cb) ->
      list
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
      , null
      , "SELECT * FROM `person` AS `Person` LEFT JOIN `address` AS `Address` ON `Address`.`ID` = `Person`.`addressID`"
      , [{}]
      , cb


  describe "placeholder", ->
