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

  lastBuild: (callback) ->
    promise = @_cache 'build', 'last', =>
      @attributes().wrap Travis.Entity.build, (attributes, inner) =>
        build = @build
          id:           attributes.lastBuildId
          number:       attributes.lastBuildNumber
          state:        attributes.lastBuildState
          duration:     attributes.lastBuildDuration
          startedAt:    attributes.lastBuildStartedAt
          finishedAt:   attributes.lastBuildFinishedAt
          repositoryId: attributes.id
        build.then (b) -> inner.succeed(b)
    promise.then(callback)

  build: (options, callback) ->
    options = { number: options.toString() } if typeof(options) == 'number'
    options = { number: optsion            } if typeof(options) == 'string'

    if options.id
      promise = Travis.Promise.succeed @session.build(options)
    else
      promise = @_cache 'build', 'number', options.number, =>
        @attributes('repositoryId').wrap (a) =>
          options.repositoryId = a.repositoryId
          @session.build(options)

    promise.expect(Travis.Entity.build).then(callback)

  builds: (options, callback) ->
    promise = @session.load @_url('/builds'), options, callback, (result) -> result.builds
    promise.iterate(Travis.Entity.build)

  _url: (suffix = "") ->
    attributes = @_store().data
    "/repos/#{attributes.id || attributes.slug}#{suffix}"

  _fetch: ->
    @session.load @_url()
