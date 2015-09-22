# Check definitions
# =================================================
# This contains configuration definitions for the
# [alinex-validator](http://alinex.github.io/node-validator).

# SSH Settings
# -------------------------------------------------
ssh =
  title: "Remote Server"
  description: "a remote server ssh connection setup"
  type: 'object'
  allowedKeys: true
  mandatoryKeys: ['host', 'port', 'username']
  keys:
    host:
      title: "Hostname or IP Address"
      description: "the hostname or IP address to connect to"
      type: 'or'
      or: [
        type: 'hostname'
      ,
        type: 'ipaddr'
      ]
    port:
      title: "Port NUmber"
      description: "the port on which to connect using ssh protocol"
      type: 'port'
      default: 22
    username:
      title: "Username"
      description: "the username to use for the connection"
      type: 'string'
    password:
      title: "Password"
      description: "the password to use for connecting"
      type: 'string'
      optional: true
    privateKey:
      title: "Private Key"
      description: "the private key file to use for OpenSSH authentication"
      type: 'string'

# Database settings
# -------------------------------------------------
database =
  title: "Access Settings"
  description: "the settings used to connect to the database"
  type: 'object'
  mandatoryKeys: true
  entries:
    type:
      title: "Type"
      description: "the type of database server"
      type: 'string'
      lowerCase: true
      values: ['mysql', 'postgres', 'sqlite']
    host:
      title: "Hostname"
      description: "the hostname or ip address to connect to"
      type: 'hostname'
      default: 'localhost'
    port:
      title: "Port"
      description: "the port mysql is listening"
      type: 'integer'
      optional: true
    database:
      title: "Database Name"
      description: "the name of the database to use"
      type: 'string'
    user:
      title: "Username"
      description: "the name used to log into the database"
      type: 'string'
    password:
      title: "Password"
      description: "the password to login"
      type: 'string'
      optional: true
    charset:
      title: "Default Charset"
      description: "the charset used if no other given"
      type: 'string'
      optional: true
    timezone:
      title: "Timezone"
      description: "the timezone to use"
      type: 'string'
      optional: true
    connectTimeout:
      title: "Connection Timeout"
      description: "the time till a connection should be established"
      type: 'interval'
      unit: 'ms'
      optional: true
    connectionLimit:
      title: "Connection Pool Limit"
      description: "the maximum number of parallel used connections"
      type: 'integer'
      default: 10
    ssh: ssh
    cluster:
      title: "Cluster"
      description: "the clusters to which this database belongs"
      type: 'array'
      toArray: true
      entries:
        type: 'string'
        minLength: 3

# Export objects
# -------------------------------------------------
module.exports =
  title: "Database Configuration"
  description: "the settings used for accessing the databases"
  type: 'object'
  entries: database

