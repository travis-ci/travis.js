class Travis.Entity.repository extends Travis.Entity
  attributeNames: [
    'id', 'slug', 'description', 'lastBuildId', 'lastBuildNumber', 'lastBuildState',
    'lastBuildDuration', 'lastBuildStartedAt', 'lastBuildFinishedAt', 'githubLanguage'
  ]

  _fetch: ->
    attributes = @_store().data
    @session.load "/repos/#{attributes.id || attributes.slug}"
