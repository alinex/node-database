# Object to SQL  Mapping
# =================================================


# Conversion of Subparts
# -------------------------------------------------

# ### SELECT fields
field =
  title: "Field"
  description: "the list of fields to return"
  type: 'or'
  or: [
    title: "Fieldname"
    type: 'string'
  ,
    title: "List of Fields"
    type: 'array'
    entries:
      type: 'or'
      or: [
        title: "Fieldname"
        type: 'string'
      ,
        title: "Named Fields"
        type: 'object'
        entries: [
          key: /^$(value)/
          type: 'object'
        ,
          key: /^[^$]/
          type: 'string'
        ]
      ]
  ,
    title: "Named Fields"
    type: 'object'
    entries: [
      key: /^$(value)/
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

# ### FROM table
table =
  title: "Table"
  description: "the table data will be retrieved"
  type: 'or'
  or: [
    type: 'string'
  ,
    type: 'array'
    entries:
      type: 'string'
  ,
    type: 'object'
    entries: [
      type: 'string'
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


# Complete
# -------------------------------------------------

module.exports.schema =
  title: "SQL Object"
  selection: "the SQL as object notation"
  type: 'or'
  or: [select]
