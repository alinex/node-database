# Object to SQL  Mapping
# =================================================


# Conversion of Subparts
# -------------------------------------------------

# ### SELECT fields
field =
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

# ### FROM table
table =
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
  type: 'object'
  allowedKeys: true
  mandatoryKeys: ['select']
  keys:
    select: field
    from: table


# Complete
# -------------------------------------------------

module.exports.schema =
  type: 'or'
  or: [select]
