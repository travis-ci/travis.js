class Travis.Session
  constructor: (options = {}) ->
    Travis._setup()

    options                  = { url: Travis.endpoints[options] || options } if typeof(options) == 'string'
    @_options                = options
    headers                  = { "Accept": "application/vnd.travis-ci.2+json" }
    headers['Authorization'] = "token #{options.token}" if options.token?
    @http                    = new Travis.HTTP(headers: headers, base: options.url || Travis.endpoints.default)
    @data                    = {}

    Travis.Delegator.define Travis.HTTP, this, @github
    Travis.Delegator.define Travis.HTTP, this, @github()

    Travis.Delegator.defineSimple 'each', this, @accounts
    Travis.Delegator.defineSimple 'each', this, @broadcasts
    Travis.Delegator.defineSimple 'each', this, @repositories

  account: (options, callback) ->
    options = { login: options } if typeof(options) == 'string'
    @entity 'account', options, callback

  accounts: (options, callback) ->
    promise = @load '/accounts', options, callback, (result) -> result.accounts
    promise.iterate(Travis.Entity.account)

  build: (options, callback) ->
    options = { id: options } if typeof(options) == 'number'
    @entity 'build', options, callback

  broadcasts: (options, callback) ->
    promise = @load '/broadcasts', options, callback, (result) -> result.broadcasts
    promise.iterate(Travis.Entity.broadcast)

  repository: (options, callback) ->
    options = { slug: options } if typeof(options) == 'string'
    options = { id:   options } if typeof(options) == 'number'
    @entity 'repository', options

  repositories: (options, callback) ->
    promise = @load '/repos', options, callback, (result) -> result.repos
    promise.iterate(Travis.Entity.repository)

  load: (path, options, callback, format) ->
    format ?= (e) -> e
    if typeof(options) == 'function'
      otherCallback = options
      options = {}

    @http.get(path, options)
      .wrap (response) => format @loadData(response.body)
      .then otherCallback
      .then callback

  loadData: (data) ->
    result = {}
    for entityKey, value of data
      if entityType       = Travis.EntityMap.one[entityKey]
        result[entityKey] = entity if entity = @entity(entityType, value)
      else if entityType  = Travis.EntityMap.many[entityKey]
        result[entityKey] = []
        for attributes in value
          result[entityKey].push(entity) if entity = @entity(entityType, attributes)
    result

  _entity: (entityType, indexKey, index) ->
    prototype   = Travis.Entity[entityType.name] || Travis.Entity
    storeAccess = => @_entityData(entityType, indexKey, index)
    new prototype(this, storeAccess)

  _entityData: (entityType, indexKey, index) ->
    store = @data[entityType.name] ?= {}
    store = store[indexKey]        ?= {}
    store[index]                   ?= { data: {}, complete: false, cache: {} }

  _parseField: (fieldName, fieldValue) ->
    if /_at$/.test(fieldName) and fieldValue?
      new Date Date.parse(fieldValue)
    else
      fieldValue

  _readField: (object, field) ->
    return object[@_clientName(field)] || object[@_apiName(field)] if typeof(field) == 'string'
    result = []
    for subfield in field
      value = @_readField(object, subfield)
      return undefined if value == undefined
      result.push value
    result

  _clientName: (string) ->
    string.replace /_([a-z])/g, (g) -> g[1].toUpperCase()

  _apiName: (string) ->
    string.replace /[A-Z]/g, (g) -> "_" + g[0].toLowerCase()

  entity: (entityType, data, callback, complete = false) ->
    if typeof(entityType) == 'string'
      entityName = entityType
      entityType = Travis.Entities[entityType]
      throw new Error "unknown entity type #{entityName}" unless entityType?
    entity = null
    for indexKey in entityType.index
      if index                        = @_readField(data, indexKey)
        entity                       ?= @_entity(entityType, indexKey, index)
        store                         = @_entityData(entityType, indexKey, index)
        store.complete                = true if complete
        store.data[@_clientName(key)] = @_parseField(key, value) for key, value of data
    entity.then(callback)

  session: (options) ->
    for key, value of @_options
      options[key] ?= value
    new Travis.Session(options)

  config: (callback) ->
    @config.promise ?= @http.get('/config').wrap (response) -> response.body.config
    @config.promise.then(callback)

  github: (callback) ->
    @github.promise ?= @config().wrap (config) -> new Travis.HTTP(base: config.github.api_url)
    @github.promise.then(callback)

  authenticate: (options, callback) ->
    options = { token: options } if typeof(options) == 'string'
    if options.token?
      promise = new Travis.Promise
      promise.succeed @session(token: options.token)
    else if options.githubToken?
      promise = @http.post('/auth/github', github_token: options.githubToken).wrap (response) =>
        @session(token: response.body.access_token)
    else if options.githubUser? and options.githubPassword?
      promise.fail new Error "github password auth not yet supported"
    else
      promise = new Travis.Promise (promise) ->
        promise.fail new Error "token or githubToken required"
    promise.then(callback)

  clearCache: ->
    @data = {}
    this
