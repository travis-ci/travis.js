class Travis.Entity.build extends Travis.Entity
  attributeNames: [
    'id', 'repositoryId', 'commitId', 'number', 'pullRequest', 'pullRequestNumber', 'pullRequestTitle',
    'config', 'state', 'startedAt', 'finishedAt', 'duration', 'jobIds'
  ]

  computedAttributes:
    push:
      dependsOn: ['pullRequest']
      compute: (attributes) -> !attributes.pullRequest

  _fetch: ->
    attributes = @_store().data
    if attributes.id
      @session.load "/builds/#{attributes.id}"
    else
      @session.load "/repos/#{attributes.repositoryId}/builds", number: attributes.number
