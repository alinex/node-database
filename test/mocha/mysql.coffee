chai = require 'chai'
expect = chai.expect
Config = require 'alinex-config'
#require('alinex-error').install()

database = require '../../src/index'

describe "Mysql access", ->

  describe "native", ->

    it "should allow connections to database", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.connect (err, conn) ->
          conn.query 'SELECT 2 + 2 AS solution', (err, rows, fields) ->
            throw err if err
            console.log 'The database calculated 2+2 =', rows[0].solution
            conn.release()
            db.close (err) ->
              done()

    it.only "should allow connections through ssh", (done) ->
      @timeout 30000
      database.instance 'test-ssh', (err, db) ->
        throw err if err
        db.connect (err, conn) ->
          conn.query 'SELECT 2 + 2 AS solution', (err, rows, fields) ->
            throw err if err
            console.log 'The database calculated 2+2 =', rows[0].solution
            conn.release()
            db.close (err) ->
              done()

  describe "exec", ->

    it "should create a table", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.exec 'DROP TABLE IF EXISTS numbers', (err, num) ->
          expect(err, 'error after drop').to.not.exist
          db.exec '''
            CREATE TABLE numbers (
              id INT AUTO_INCREMENT PRIMARY KEY,
              num INT,
              name VARCHAR(10),
              comment VARCHAR(32)
            )
            ''', (err, num) ->
            expect(err, 'error').to.not.exist
            done()

    it "should execute multiple inserts", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.exec '''
        INSERT INTO numbers (num, name) VALUES (1, 'one'), (2, 'two'), (3, 'three')
        ''', (err, num) ->
          expect(err, 'error').to.not.exist
          expect(num, 'affectedRows').to.equal 3
          done()

    it "should execute multiple inserts", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.exec '''
        INSERT INTO numbers SET num=9, name='nine'
        ''', (err, num, id) ->
          expect(err, 'error').to.not.exist
          expect(num, 'affectedRows').to.equal 1
          expect(id, 'insertId').to.equal 4
          done()

    it "should update one record", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.exec '''
        UPDATE numbers SET comment='max' WHERE num=9
        ''', (err, num) ->
          expect(err, 'error').to.not.exist
          expect(num, 'affectedRows').to.equal 1
          done()

    it "should update multiple records", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.exec '''
        UPDATE numbers SET comment='ok' WHERE num<9
        ''', (err, num) ->
          expect(err, 'error').to.not.exist
          expect(num, 'affectedRows').to.equal 3
          done()

  describe "analysis", ->

#analysis:
#SHOW tables
#SHOW columns FROM numbers
#

  describe "query", ->

    it "should get complete list of entries", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.list '''
        SELECT * FROM numbers
        ''', (err, res) ->
          expect(err, 'error').to.not.exist
          expect(res, 'results').to.deep.equal [
            id: 1
            num: 1
            name: "one"
            comment: "ok"
          ,
            id: 2
            num: 2
            name: "two"
            comment: "ok"
          ,
            id: 3
            num: 3
            name: "three"
            comment: "ok"
          ,
            id: 4
            num: 9
            name: "nine"
            comment: "max"
          ]
          done()

    it "should get complete list of entries", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.record '''
        SELECT * FROM numbers WHERE num=2
        ''', (err, res) ->
          expect(err, 'error').to.not.exist
          expect(res, 'results').to.deep.equal
            id: 2
            num: 2
            name: "two"
            comment: "ok"
          done()

    it "should get one value", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.value '''
        SELECT comment FROM numbers WHERE num=9
        ''', (err, res) ->
          expect(err, 'error').to.not.exist
          expect(res, 'result').to.equal 'max'
          done()

    it "should get one column", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.column '''
        SELECT name FROM numbers
        ''', (err, res) ->
          expect(err, 'error').to.not.exist
          expect(res, 'result').to.deep.equal ['one', 'two', 'three', 'nine']
          done()
