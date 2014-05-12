class Travis.Entity.broadcast extends Travis.Entity
  attributeNames: [ 'id', 'message' ]
  _fetch: -> @session.broadcasts()
