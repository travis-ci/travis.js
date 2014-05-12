Travis.Entities =

  account:
    index: ['login', ['type', 'id']]
    one:   ['account']
    many:  ['accounts']

  broadcast:
    index: ['id']
    one:   ['broadcast']
    many:  ['broadcasts']

  build:
    index: ['id', ['repository_id', 'number']]
    one:   ['build']
    many:  ['builds']

  repository:
    index: ['id', 'slug']
    one:   ['repo', 'repository']
    many:  ['repos', 'repositories']

Travis.EntityMap = { one: {}, many: {} }
for name, entity of Travis.Entities
  entity.name                = name
  Travis.EntityMap.one[key]  = entity for key in entity.one
  Travis.EntityMap.many[key] = entity for key in entity.many
