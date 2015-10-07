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
      title: "Port Number"
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
    passphrase:
      title: "Passphrase"
      description: "the passphrase used to decrypt an encrypted private key"
      type: 'string'
    localHostname:
      title: "Local Hostname"
      description: "the host used for hostbased user authentication"
      type: 'string'
    localUsername:
      title: "Local User"
      description: "the username used for hostbased user authentication"
      type: 'string'
    keepaliveInterval:
      title: "Keepalive"
      description: "the interval for the keepalive packets to be send"
      type: 'interval'
      unit: 'ms'
      default: 1000
    readyTimeout:
      title: "Ready TImeout"
      description: "the time to wait for the ssh handshake to succeed"
      type: 'interval'
      unit: 'ms'
      default: 20000

# Mysql Database
# -------------------------------------------------
mysql =
  title: "Mysql Access"
  description: "the settings used to connect to the mysql database"
  type: 'object'
  allowedKeys: true
  keys:
    type:
      title: "Type"
      description: "the type of database server"
      type: 'string'
      lowerCase: true
      values: ['mysql']
    host:
      title: "Hostname"
      description: "the hostname or ip address to connect to"
      type: 'hostname'
      default: 'localhost'
    port:
      title: "Port"
      description: "the port, the database is listening"
      type: 'integer'
      default: 3306
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

# Mysql Database
# -------------------------------------------------
postgres =
  title: "PostgreSQL Access"
  description: "the settings used to connect to the postgres database"
  type: 'object'
  allowedKeys: true
  keys:
    type:
      title: "Type"
      description: "the type of database server"
      type: 'string'
      lowerCase: true
      values: ['postgres']
    host:
      title: "Hostname"
      description: "the hostname or ip address to connect to"
      type: 'hostname'
      default: 'localhost'
    port:
      title: "Port"
      description: "the port, the database is listening"
      type: 'integer'
      default: 5432
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
    connectTimeout:
      title: "Connection Timeout"
      description: "the time till a connection should be established"
      type: 'interval'
      unit: 'ms'
      optional: true

# Export objects
# -------------------------------------------------
module.exports =
  title: "Connections"
  description: "the database connections"
  type: 'object'
  entries: [
    title: "Connection"
    description: "the connection to one database"
    type: 'object'
    allowedKeys: true
    mandatoryKeys: ['server']
    keys:
      ssh: ssh
      server:
        title: "Access"
        description: "the settings used to connect to the database"
        type: 'or'
        or: [mysql, postgres]
      pool:
        title: "Connection Pool"
        description: "the connection pool"
        type: 'object'
        allowedKeys: true
        keys:
          limit:
            title: "Connection Pool Limit"
            description: "the maximum number of parallel used connections"
            type: 'integer'
            default: 10
          cluster:
            title: "Cluster"
            description: "the clusters to which this database belongs"
            type: 'array'
            toArray: true
            entries:
              type: 'string'
              minLength: 3
  ]
