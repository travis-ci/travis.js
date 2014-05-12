class Travis.Entity.build extends Travis.Entity
  attributeNames: [
    'id', 'repositoryId', 'commitId', 'number', 'pullRequest', 'pullRequestNumber', 'pullRequestTitle',
    'config', 'state', 'startedAt', 'finishedAt', 'duration', 'jobIds'
  ]

  computedAttributes:
    push:
      dependsOn: ['pullRequest']
      compute: (attributes) -> !attributes.pullRequest

  restart: (callback) -> @_action 'restart', callback
  cancel:  (callback) -> @_action 'cancel',  callback

  _action: (action, callback) ->
    promise = new Travis.Promise (promise) =>
      @id (id) =>
        @session.http.post "/builds/#{id}/#{action}", (result) =>
          promise.succeed @reload()
    promise.run().then(callback)

  _fetch: ->
    attributes = @_store().data
    if attributes.id
      @session.load "/builds/#{attributes.id}"
    else
      @session.load "/repos/#{attributes.repositoryId}/builds", number: attributes.number
