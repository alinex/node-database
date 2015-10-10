# Object Schema
# =================================================

select =
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

from =
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

# Everything together
# -------------------------------------------------

module.exports =
  type: 'or'
  or: [
    type: 'object'
    allowedKeys: true
    mandatoryKeys: ['select']
    keys:
      select: select
      from: from
  ]
