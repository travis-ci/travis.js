Travis.Entities =
  list: ->
    entities = []
    for name, entity of Travis.Entities
      entities.push(entity) if /^[A-Z]/.test(name)
    entities

  map: ->
    mapping = one: {}, many: {}
    for entity in Travis.Entities.list()
      mapping.one[key]  = entity for key in entity.one
      mapping.many[key] = entity for key in entity.many
    mapping
