Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 0.1.3 (2015-11-26)
-------------------------------------------------
- Fix retrieve of first value.
- Fixed error reporting in podtgres driver.
- Fix bug in query result parsing with empty results.

Version 0.1.2 (2015-11-20)
-------------------------------------------------
- Allow all tests to run.
- Finished mysql driver optimization and did the same for postgresql.
- Simplified mysql driver functions.
- Fix call with connections on mysql driver.
- Merge branch 'master' of https://github.com/alinex/node-database
- Support ? placeholder for postgresql.
- Connection tests on postgresql.
- Added test cases for connection based methods in mysql.
- Allow use of given connection in easy access methods.
- Bug fixed: postgres exec() parameter data were not transmitted.

Version 0.1.1 (2015-11-17)
-------------------------------------------------
- Fix syntax error after reporting of error.
- Added database name to connection error message.
- Document the direct access with examples.
- Optimized code.
- Fixed postgres driver to run queries correctly, again.
- Add Error message if given database is not defined.

Version 0.1.0 (2015-11-06)
-------------------------------------------------
- Fix bug preventing query call because of debug optimization.
- Finished support fro short function syntax in postgresql driver.
- Added propper debugging for connection handling and query protocol.
- Added postgresql driver with working nativ handling.
- Set travis for postgresql.
- Added where support in object notation.
- Add semicolon after created queries.
- Implemented more functions in the object2sql conversion.
- Multistatement handling allowed.
- Added distinct modifier.
- Change debug flag to database instead 'db' to be common in the alinex scheme.
- Start implementing function.

Version 0.0.1 (2015-10-16)
-------------------------------------------------
- Remove postgres/sqlite till used.
- First usable version (mysql only).
- Fixed tests to work with real database tests on all.
- Fixed structure for second test table.
- Restructured test script for object notation.
- Restructure sources and add real db tests to object notation.
- Support join syntax in object.
- Allow ? to be used as placeholder in object structure, too.
- Add travis and coveralls.
- Added documentation.
- Restructuring object transformation.
- Made  object check schema as extra file.
- Started object to sql conversion.
- Allow ssh tunneling for database connections.
- Mysql wrapper running.
- Base API for connecting started...
- Restructured config to use different options depending on database type.
- Added link for elastic search module.
- Optimized config Schema.
- Fix config schema.
- Updated sources to newer config.
- Added files from previous mysql only module.
- Add subpackages.
- Plan module in mindmap.
- Initial commit

