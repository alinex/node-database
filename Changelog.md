Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 1.1.1 (2017-08-24)
-------------------------------------------------
Update pg driver version

- Update pg version
- Add notification type in postgres

Version 1.1.0 (2017-03-27)
-------------------------------------------------
- Allow all tests to run.
- Upgrade alinex-util@2.5.1, pg@6.1.5, alinex-validator@2.1.2, async@2.2.0, debug@2.6.3, mysql@2.13.0, alinex-builder@2.4.1
- Update alinex-util@2.5.1, alinex-validator@2.1.2, portfinder@1.0.13, async@2.2.0, debug@2.6.3, alinex-builder@2.4.1
- Replace alinex-sshtunnel with newer alinex-ssh.
- Calculate debug strings only if enabled.
- Restructure for new documentation.
- Rename links to Alinex Namespace.
- Add copyright sign.
- Smaller typo fixes.
- return error if problems establishing the tunnel.
- Upgrade alinex-sshtunnel@1.2.0
- Test simple failure calls.
- Use pg-native automatically.
- Enable pool with additional min setting.
- Remove pool debugging to fix for pg@6.0.0
- Upgraded to alinex-config@1.1.6, alinex-validator@1.6.6, alinex-util@2.3.1, mysql@2.11.1, alinex-builder@2.1.13, pg@6.0.1

Version 1.0.1 (2016-05-06)
-------------------------------------------------
- Update util and async calls.
- Upgraded async, util, chalk, pg and builder packages.
- Fixed general link in README.

Version 1.0.0 (2016-02-05)
-------------------------------------------------
- Updated postgres and alinex packages.
- updated ignore files.
- Fixed style of test cases.
- Fixed lint warnings in code.
- Updated meta data of package and travis build versions.
- Updated copyright, travis and npmignore.

Version 0.1.4 (2016-01-26)
-------------------------------------------------
- Compressed debug of sql parameters in postgres.
- added debug level for error reporting.
- Better pool information in debug mode of postgresql.
- Fixed typo in documentation.

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

