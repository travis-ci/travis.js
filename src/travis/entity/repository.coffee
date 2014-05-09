class Travis.Entity.repository extends Travis.Entity
  attributeNames: [
    'id', 'slug', 'description', 'lastBuildId', 'lastBuildNumber', 'lastBuildState',
    'lastBuildDuration', 'lastBuildStartedAt', 'lastBuildFinishedAt', 'githubLanguage'
  ]

  computedAttributes:
    ownerName:
      dependsOn: ['slug']
      compute: (attributes) -> attributes.slug.split('/', 1)[0]
    name:
      dependsOn: ['slug']
      compute: (attributes) -> attributes.slug.split('/', 2)[1]

  _fetch: ->
    attributes = @_store().data
    @session.load "/repos/#{attributes.id || attributes.slug}"
