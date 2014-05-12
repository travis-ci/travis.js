'use strict'

Travis                    = (options) -> new Travis.Session(options)
Travis.version            = '0.1.1'
Travis.endpoints          = org: 'https://api.travis-ci.org', pro: 'https://api.travis-ci.com'
Travis.endpoints.default  = Travis.endpoints.org
Travis.callbacks          = {}
Travis.globalCallbacks    = []
Travis.callbacksFor       = (event) -> Travis.globalCallbacks.concat(Travis.callbacks[event] || [])
Travis.notify             = (event, payload) -> callback(data: payload, type: event) for callback in Travis.callbacksFor(event)
Travis.debug              = -> Travis.on (e) -> console.log(e.type, e.data)

Travis.on = (events..., callback) ->
  if events.length == 0
    Travis.globalCallbacks.push(callback)
  else
    for event in events
      Travis.callbacks[event] = [] unless Travis.callbacks[event]?
      Travis.callbacks[event].push(callback)

Travis._setup  = ->
  for name, entity of Travis.Entity
    entity._setup() if entity._setup?
  Travis._setup = ->

module.exports = Travis if module?
window.exports = Travis if window?
@Travis        = Travis

Travis.Delegator =
  define: (methods..., caller, constructor) ->
    @eachMethod methods..., (method) => @delegate(caller, constructor, method)

  defineNested: (methods..., caller, constructor) ->
    @eachMethod methods..., (method) => @delegateNested(caller, constructor, method)

  defineSimple: (methods..., caller, constructor) ->
    @eachMethod methods..., (method) => @delegateSimple(caller, constructor, method)

  eachMethod: (methods..., callback) ->
    for method in methods
      if typeof(method) == 'string'
        callback(method)
      else if method.delegationMethods
        callback(subMethod) for subMethod in method.delegationMethods()
      else if method.prototype?
        callback(subMethod) for subMethod of method.prototype
      else
        callback(subMethod) for subMethod of method

  delegate: (caller, constructor, method) ->
    return if method.indexOf('_') == 0
    constructor[method] ?= (args..., callback) ->
      if typeof(callback) == 'function'
        constructor[method].apply(this, args).then(callback)
      else
        args.push(callback)
        outerPromise = if constructor.then? then constructor else constructor.call(caller)
        new Travis.Promise (delegationPromise) ->
          outerPromise.then (outerResult) ->
            innerPromise = outerResult[method].apply(outerResult, args)
            innerPromise.then (innerResult) -> delegationPromise.succeed(innerResult)
            innerPromise.catch (innerError) -> delegationPromise.fail(innerError)
          outerPromise.catch (outerError)   -> delegationPromise.fail(outerError)

  delegateNested: (caller, constructor, method) ->
    constructor[method] ?= (args...) ->
      constructor.call caller, (result) ->
        result[method].call(result, args...)

  delegateSimple: (caller, constructor, method) ->
    constructor[method] ?= constructor.call(caller)[method]
Travis.Entities =

  account:
    index: ['login', ['type', 'id']]
    one:   ['account']
    many:  ['accounts']

  broadcast:
    index: ['id']
    one:   ['broadcast']
    many:  ['broadcasts']

  build:
    index: ['id', ['repository_id', 'number']]
    one:   ['build']
    many:  ['builds']

  repository:
    index: ['id', 'slug']
    one:   ['repo', 'repository']
    many:  ['repos', 'repositories']

Travis.EntityMap = { one: {}, many: {} }
for name, entity of Travis.Entities
  entity.name                = name
  Travis.EntityMap.one[key]  = entity for key in entity.one
  Travis.EntityMap.many[key] = entity for key in entity.many

class Travis.Entity
  @_setup = ->
    defineAttribute = (attr) =>
      @::[attr]    ?= (callback) -> @attribute(attr, callback)
    defineAttribute(attribute) for attribute in @::attributeNames     if @::attributeNames?
    defineAttribute(attribute) for attribute of @::computedAttributes if @::computedAttributes?

  constructor: (session, store) ->
    @session = session
    @_store  = store
    @_setup()

  complete: (checkAttributes = true) ->
    return true unless @_fetch?
    return true if checkAttributes and @attributeNames? and @hasAttributes()
    @_store().complete

  hasAttributes: (list...) ->
    list = @attributeNames if list.length == 0
    data = @_store().data
    for attribute in list
      if dependsOn = @computedAttributes?[attribute]?.dependsOn
        return false unless @hasAttributes(dependsOn...)
      else
        return false if data[@session._clientName(attribute)] == undefined
    return true

  attributes: (list..., callback) ->
    if typeof(callback) == 'string'
      list.push(callback)
      callback = null

    if list.length == 0
      list = @attributeNames
      if @computedAttributes?
        list.push(key) for key, value of @computedAttributes

    if @complete(false) or @hasAttributes(list...)
      promise = new Travis.Promise (p) => p.succeed @_attributes(list)
    else
      promise = @_fetch().wrap =>
        @_store().complete = true
        @_attributes(list)
    promise.then(callback)

  attribute: (name, callback) ->
    @attributes(name).wrap((a) -> a[name]).then(callback)

  reload: ->
    store          = @_store()
    store.cache    = {}
    store.data     = {}
    store.complete = false
    this

  _setup: ->

  _attributes: (list) ->
    data    = @_store().data
    result  = {}
    compute = {}
    for name in list
      if computation = @computedAttributes?[name]
        compute[name] = computation
      else
        result[name] = data[@session._clientName(name)]
    for key, value of compute
      result[key] = value.compute(data)
    result

  _cache: (bucket..., key, callback) ->
    cache               = @_store().cache
    cache[bucket]      ?= {}
    cache[bucket][key] ?= callback.call(this)

  then: (callback) ->
    callback(this) if callback?
    return this

  run: -> this
  catch: -> this
  onSuccess: -> this
  onFailure: -> this
  wrap: (delegations..., wrapper) ->
    Travis.Promise.succeed(wrapper(this)).expect(delegations...)
class Travis.HTTP
  @delegationMethods: -> ['get', 'head', 'post', 'put', 'patch', 'delete', 'request']

  get:    (path, params, options) -> @request('GET',    path, params, options)
  head:   (path, params, options) -> @request('HEAD',   path, params, options)
  post:   (path, params, options) -> @request('POST',   path, params, options)
  put:    (path, params, options) -> @request('PUT',    path, params, options)
  patch:  (path, params, options) -> @request('PATCH',  path, params, options)
  delete: (path, params, options) -> @request('DELETE', path, params, options)

  request: (method, path, params, options) ->
    options            = @prepareRequest(method, path, params, options)
    http               = this
    promise            = new Travis.Promise (promise) ->
      generateError    = (status, headers, body) ->
        error          = new Error("HTTP #{status.toString()}: #{body}")
        error.response = generateResponse(status, headers, body)
        return error
      generateResponse = (status, headers, body) ->
        response       = { status: status, headers: headers, body: body }
        response.body  = JSON.parse(body) if body? and method != 'HEAD' and /^application\/json/.test(headers['content-type'])
        Travis.notify('http:response', response)
        return response
      sendRequest      = (opt, updatedOpt) ->
        opt[key]       = value for key, value of updatedOpt
        Travis.notify('http:request', opt)
        http.rawRequest opt, (status, headers, body) ->
          switch status
            when 200, 201, 204 then promise.succeed generateResponse(status, headers, body)
            when 301, 302, 303 then sendRequest(opt, url: headers['location'], method: if method == 'HEAD' then method else 'GET')
            when 307, 308      then sendRequest(opt, url: headers['location'])
            else                    promise.fail generateError(status, headers, body)
      sendRequest(options)
    promise.run() if method != 'HEAD' and method != 'GET'
    promise.then(options.callback) if options.callback?
    return promise

  prepareRequest: (method, path, params, options) ->
    throw new Error "path is missing" unless path?
    options            = { callback: options } if typeof(options) == 'function'
    options            = { } unless options?
    options.method     = method
    options.headers    = { } unless options.headers?
    options.url        = if /^https?:/.test(path) then path else "#{@base}#{path}"
    for key, value of @defaultHeaders
      options.headers[key] = value unless options.headers[key]?
    if typeof(params) == 'function'
      options.callback = params
      params           = null
    @setParams options, params if params?
    return options

  setParams: (options, params) ->
    if options.method == 'HEAD' or options.method == 'GET'
      @setQueryParams(options, params)
    else
      @setBody(options, params)

  setBody: (options, params) ->
    if typeof(params) != 'string'
      options.headers['Content-Type'] = 'application/json'
      params = JSON.stringify(params)
    options.body = params

  setQueryParams: (options, params) ->
    separator = if options.url.indexOf('?') >= 0 then '&' else '?'
    if typeof(params) == 'string'
      options.url += "#{separator}#{params}"
    else
      for key, value of params
        options.url += "#{separator}#{encodeURIComponent(key)}=#{encodeURIComponent(value)}"
        separator = '&'

  constructor: (options) ->
    @base                          = options.base
    @defaultHeaders                = options.headers || {}
    @defaultHeaders['User-Agent'] ?= "travis.js/#{Travis.version} #{Travis.System.info()}"

    if XMLHttpRequest?
      xhrHeaders  = options.xhrHeaders || ["content-type", "cache-control", "expires", "etag", "last-modified"]
      @rawRequest = (options, callback) ->
        req       = new XMLHttpRequest()
        req.open(options.method, options.url, true)
        for name, value of options.headers
          req.setRequestHeader(name, value) if name.toLowerCase() != 'user-agent'
        req.onreadystatechange = ->
          if req.readyState == 4
            headers = {}
            headers[header.toLowerCase()] = req.getResponseHeader(header) for header in xhrHeaders
            callback(req.status, headers, req.responseText)
        req.send(options.body)

    else
      @url               = require('url')
      @adapters          = "http:": require('http'), "https:": require('https')
      @rawRequest        = (options, callback) ->
        parsed           = @url.parse(options.url)
        responseBody     = ""
        adapter          = @adapters[parsed.protocol] || @adapters['http:']
        httpOptions      = host: parsed.hostname, path: parsed.path, method: options.method, headers: options.headers
        httpOptions.port = parsed.port if parsed.port?
        request          = adapter.request httpOptions, (response) ->
          response.on 'data', (chunk) -> responseBody += chunk
          response.on 'end', ->
            callback(response.statusCode, response.headers, responseBody)
        request.on 'error', (error) -> throw(error)
        request.write options.body if options.body?
        request.end()

class Travis.Promise
  @succeed: (data) -> (new Travis.Promise).succeed(data)

  constructor: (closure) ->
    @_onSuccess = []
    @_onFailure = []
    @data       = null
    @closure    = closure
    @setState('sleeping')

  setState: (stateName, data) ->
    @data      = data if data?
    @sleeping  = stateName == 'sleeping'
    @running   = stateName == 'running'
    @failed    = stateName == 'failed'
    @succeeded = stateName == 'succeeded'
    return this

  run: ->
    if @sleeping
      @setState('running')
      @closure(this)
    return this

  succeed: (data) ->
    @setState('succeeded', data)
    Travis.notify('promise:succeed', data)
    callback(@data) for callback in @_onSuccess
    @_onSuccess = []
    @_onFailure = []
    return this

  fail: (data) ->
    @setState('failed', data)
    Travis.notify('promise:fail', data)
    callback(@data) for callback in @_onFailure
    @_onSuccess = []
    @_onFailure = []
    return this

  onSuccess: (callback) ->
    @then(callback, null, false)

  onFailure: (callback) ->
    @then(null, callback, false)

  wrap: (delegations..., wrapper) ->
    wrapped  = this
    promise  = new Travis.Promise -> wrapped.run()
    callback = (input) ->
      if wrapper.length > 1
         wrapper(input, promise)
       else
         promise.succeed wrapper(input)
    @then callback, ((input) -> promise.fail(input)), false
    promise.expect(delegations...)

  iterate: (delegations...) ->
    @each = (callback, errback) ->
      throw new Error "missing callback" unless callback?
      iterator = (result) -> callback(entry) for entry in result
      @then(iterator, errback)
    Travis.Delegator.defineNested(delegations..., this, @each)
    @iterate = -> this
    return this

  expect: (delegations...) ->
    Travis.Delegator.define(delegations..., this, this)
    this

  then: (callback, errback, trigger = null) ->
    trigger = (callback? or errback?) if trigger == null
    errback = ((err) => throw(@_error(err))) if callback? and errback == undefined
    if @succeeded
      callback(@data) if callback?
    else if @failed
      errback(@data) if errback?
    else
      @_onSuccess.push callback if callback?
      @_onFailure.push errback  if errback?
      @run() if trigger
    return this

  catch: (errback) ->
    @then(null, errback)
    return this

  _error: (error) ->
    if typeof(error) == 'string' then new Error(error) else error
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

Travis.System =
  info: ->
    if navigator?.userAgent?
      navigator.userAgent
    else if process?
      "node/#{process.versions.node} (#{process.platform}) v8/#{process.versions.v8}"
    else
      'unknown'

  base64: (string) ->
    if Buffer?
      new Buffer(string).toString('base64')
    else
      btoa(string)
class Travis.Entity.account extends Travis.Entity
  attributeNames: [ 'id', 'name', 'login', 'type', 'reposCount', 'subscribed' ]
  _fetch: -> @session.accounts(all: true)

class Travis.Entity.broadcast extends Travis.Entity
  attributeNames: [ 'id', 'message' ]
  _fetch: -> @session.broadcasts()

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
