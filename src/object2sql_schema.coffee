# Object to SQL  Mapping
# =================================================


# Conversion of Subparts
# -------------------------------------------------

# ### SELECT fields
field =
  title: "Fields"
  description: "the list of fields to return"
  type: 'or'
  or: [
    title: "Field"
    type: 'string'
  ,
    title: "List of Fields"
    type: 'array'
    entries:
      type: 'or'
      or: [
        title: "Field"
        type: 'string'
      ,
        title: "Named Fields"
        type: 'object'
        entries: [
          title: "Value"
          key: /^\$/
          type: 'object'
        ,
          title: "Field"
          key: /^[^$]/
          type: 'string'
        ]
      ]
  ,
    title: "Named Fields"
    type: 'object'
    entries: [
      key: /^\$/
      type: 'object'
    ,
      key: /^[^$]/
      type: 'string'
    ]
  ]

# ### DISTINCT
distinct =
  title: "Distinct Row"
  description: "a flag triggering remove of duplicate results"
  type: 'boolean'

# ### join definition for tables
join =
  type: 'object'
  allowedKeys: true
  keys:
    join:
      type: 'string'
      list: ['left', 'right', 'inner', 'outer']
    on:
      type: 'object'
      entries: [
        type: 'string'
      ]

# ### FROM table
table =
  title: "Tables"
  description: "the table data will be retrieved"
  type: 'or'
  or: [
    title: "Table"
    type: 'string'
  ,
    title: "List of Tables"
    type: 'array'
    entries:
      type: 'or'
      or: [
        title: "Table"
        type: 'string'
      ,
        title: "Table Object"
        type: 'object'
        entries: [
          type: 'or'
          or: [
            join
          ,
            title: "Named Table"
            type: 'or'
            or: [
              join
            ,
              type: 'string'
            ]
          ]
        ]
      ]
  ,
    title: "Table Object"
    type: 'object'
    entries: [
      type: 'or'
      or: [
        join
      ,
        title: "Named Table"
        type: 'or'
        or: [
          join
        ,
          type: 'string'
        ]
      ]
    ]
  ]

# Conversion of Main Types
# -------------------------------------------------

# ### SELECT
select =
  title: "Selection"
  description: "the setup of what to retrieve from the database"
  type: 'object'
  allowedKeys: true
  mandatoryKeys: ['select']
  keys:
    select: field
    distinct: distinct
    from: table
    while:
      type: 'object'


# Complete
# -------------------------------------------------

module.exports.schema =
  title: "SQL Object"
  selection: "the SQL as object notation"
  type: 'or'
  or: [select]
