###
Configuration
===================================================
To configure this module to your needs, please make a new configuration file for `/database`
context. To do so you may copy the base settings from `src/config/database.yml` into
`var/local/config/database.yml` and change it's values or put it into your applications
configuration directory.

Like supported by {@link alinex-config} you only have to
write the settings which differ from the defaults.

You may additionaly write the ssh connection details within the `/ssh/server`
section described under {@link alinex-ssh/src/configSchema.coffee}.


/database
------------------------------------------------------
{@schema #}
###


# Node Modules
# -------------------------------------------------------
sshSchema = require 'alinex-ssh/lib/configSchema'


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


# Postgresql Database
# -------------------------------------------------
postgresql =
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
      values: ['postgresql']
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
    description: "the connection to one database (key used as reference)"
    type: 'object'
    allowedKeys: true
    mandatoryKeys: ['server']
    keys:
      ssh:
        title: "SSH Connection"
        description: "the ssh connection to use"
        type: 'or'
        or: [
          title: "SSH Connection Reference"
          description: "the reference name for an defined ssh connection under
          {@link alinex-ssh/src/configSchema.coffee}"
          type: 'string'
          list: '<<<data:///ssh/server>>>'
        , sshSchema.keys.server.entries[0]
        ]
      server:
        title: "Access"
        description: "the settings used to connect to the database"
        type: 'or'
        or: [mysql, postgresql]
      access:
        title: "Auto calculated Settings"
        description: "the runtime settings used, do not set this manually"
        type: 'object'
      pool:
        title: "Connection Pool"
        description: "the connection pool"
        type: 'object'
        allowedKeys: true
        keys:
          min:
            title: "Connection Pool Minimum Size"
            description: "the minimum number of connections held to use"
            type: 'integer'
            default: 0
          limit:
            title: "Connection Pool Limit"
            description: "the maximum number of parallel used connections"
            type: 'integer'
            default: 10
          cluster:
            title: "Cluster"
            description: "the cluster to which this database belongs"
            type: 'array'
            toArray: true
            entries:
              type: 'string'
              minLength: 3
  ]
