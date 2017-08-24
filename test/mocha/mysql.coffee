chai = require 'chai'
expect = chai.expect
### eslint-env node, mocha ###

database = require '../../src/index'

describe "Mysql", ->

  after (done) ->
    database.instance 'test-mysql', (err, db) ->
      throw err if err
      db.exec 'DROP TABLE IF EXISTS numbers', (err) ->
        expect(err, 'error after drop').to.not.exist
        done()

  describe "driver", ->

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

    it.skip "should allow connections through ssh", (done) ->
      @timeout 30000
      database.instance 'test-ssh', (err, db) ->
        throw err if err
        db.connect (err, conn) ->
          expect(err, 'error on connection').to.not.exist
          conn.query 'SELECT 2 + 2 AS solution', (err, rows) ->
            throw err if err
            console.log 'The database calculated 2+2 =', rows[0].solution
            conn.release()
            db.close done

  describe "exec", ->

    it "should create a table", (done) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.exec 'DROP TABLE IF EXISTS numbers', (err) ->
          expect(err, 'error after drop').to.not.exist
          db.exec '''
            CREATE TABLE numbers (
              id INT AUTO_INCREMENT PRIMARY KEY,
              num INT,
              name VARCHAR(10),
              comment VARCHAR(32)
            )
            ''', (err) ->
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

    it "should execute with last insert id", (done) ->
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

    it "should get one record", (done) ->
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


  describe "connection", ->

    it "should get complete list of entries", (cb) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.connect (err, conn) ->
          return cb err if err
          db.list conn, '''
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
            conn.release()
            cb()

    it "should get one record", (cb) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.connect (err, conn) ->
          return cb err if err
          db.record conn, '''
          SELECT * FROM numbers WHERE num=2
          ''', (err, res) ->
            expect(err, 'error').to.not.exist
            expect(res, 'results').to.deep.equal
              id: 2
              num: 2
              name: "two"
              comment: "ok"
            conn.release()
            cb()

    it "should get one value", (cb) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.connect (err, conn) ->
          return cb err if err
          db.value conn, '''
          SELECT comment FROM numbers WHERE num=9
          ''', (err, res) ->
            expect(err, 'error').to.not.exist
            expect(res, 'result').to.equal 'max'
            conn.release()
            cb()

    it "should get one column", (cb) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.connect (err, conn) ->
          return cb err if err
          db.column conn, '''
          SELECT name FROM numbers
          ''', (err, res) ->
            expect(err, 'error').to.not.exist
            expect(res, 'result').to.deep.equal ['one', 'two', 'three', 'nine']
            conn.release()
            cb()


  describe "placeholder", ->

    it "should use in query", (cb) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.value '''
        SELECT num FROM numbers WHERE comment = ?
        ''', 'max', (err, res) ->
          expect(err, 'error').to.not.exist
          expect(res, 'result').to.equal 9
          cb()

    it "should work for insert", (cb) ->
      database.instance 'test-mysql', (err, db) ->
        throw err if err
        db.exec 'INSERT INTO numbers SET ?',
          num: 6
          name: 'six'
        , (err, res) ->
          expect(err, 'error').to.not.exist
          expect(res, 'result').to.equal 1
          cb()
