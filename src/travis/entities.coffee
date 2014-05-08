Travis.Entities =
  repository:
    index: ['id', 'slug']
    one:   ['repo', 'repository']
    many:  ['repos', 'repositories']

Travis.EntityMap = { one: {}, many: {} }
for name, entity of Travis.Entities
  entity.name                = name
  Travis.EntityMap.one[key]  = entity for key in entity.one
  Travis.EntityMap.many[key] = entity for key in entity.many
