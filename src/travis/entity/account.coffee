class Travis.Entity.account extends Travis.Entity
  attributeNames: [ 'id', 'name', 'login', 'type', 'reposCount', 'subscribed' ]
  _fetch: -> @session.accounts(all: true)
