'use strict'

Travis                    = (options) -> new Travis.Session(options)
Travis.version            = '0.1.0'
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

module.exports = Travis if module?
window.exports = Travis if window?
@Travis        = Travis

Travis.Delegator =
  define: (caller, constructor, methods...) ->
    for method in methods
      constructor[method] = @delegator(caller, constructor, method)

  delegator: (caller, constructor, method) ->
    (args..., callback) ->
      if typeof(callback) == 'function'
        constructor[method].apply(this, args).then(callback)
      else
        args.push(callback)
        outerPromise = constructor.call(caller)
        new Travis.Promise (delegationPromise) ->
          outerPromise.then (outerResult) ->
            innerPromise = outerResult[method].apply(outerResult, args)
            innerPromise.then (innerResult) -> delegationPromise.succeed(innerResult)
            innerPromise.catch (innerError) -> delegationPromise.fail(innerError)
          outerPromise.catch (outerError)   -> delegationPromise.fail(outerError)

Travis.Entities =
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
  constructor: (session, store) ->
    @session = session
    @_store  = store

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
        return false if data[@_apiName(attribute)] == undefined
    return true

  attributes: (list..., callback) ->
    list.push(callback) if typeof(callback) == 'string'

    if list.length == 0
      list = @attributeNames
      if @computedAttributes?
        list.push(key) for key, value of @computedAttributes

    if @complete(false) or @hasAttributes(list...)
      promise = new Travis.Promise (p) => p.succeed @_attributes(list)
    else
      promise = @_fetch().wrap => @_attributes(list)
    promise.then(callback)

  _attributes: (list) ->
    data    = @_store().data
    result  = {}
    compute = {}
    for name in list
      if computation = @computedAttributes?[name]
        compute[name] = computation
      else
        result[name] = data[@_apiName(name)]
    for key, value of compute
      result[key] = value.compute(data)
    result

  _clientName: (string) -> string.replace /_([a-z])/g, (g) -> g[1].toUpperCase()
  _apiName:    (string) -> string.replace /[A-Z]/g, (g) -> "_" + g[0].toLowerCase()

class Travis.HTTP
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
            else                    promise.fail generateResponse(status, headers, body)
      sendRequest(options)
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

  wrap: (wrapper) ->
    wrapped = this
    promise = new Travis.Promise -> wrapped.run()
    @then ((input) -> promise.succeed wrapper(input)), ((input) -> promise.fail(input)), false
    promise

  then: (callback, errback, trigger = null) ->
    trigger = (callback? or errback?) if trigger == null
    errback = ((err) -> throw(err))   if callback? and errback == undefined
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
class Travis.Session
  constructor: (options = {}) ->
    options                  = { url: Travis.endpoints[options] || options } if typeof(options) == 'string'
    @_options                = options
    headers                  = { "Accept": "application/vnd.travis-ci.2+json" }
    headers['Authorization'] = "token #{options.token}" if options.token?
    @http                    = new Travis.HTTP(headers: headers, base: options.url || Travis.endpoints.default)
    @data                    = {}
    Travis.Delegator.define this, @github, 'get'

  repository: (options) ->
    options = { slug: options } if typeof(options) == 'string'
    options = { id:   options } if typeof(options) == 'number'
    @entity('repository', options)

  repositories: (options, callback) ->
    @load '/repos', options, callback, (result) -> result.repos

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
    store[index]                   ?= { data: {}, complete: false }

  _parseField: (fieldName, fieldValue) ->
    if /_at$/.test(fieldName) and fieldValue?
      new Date Date.parse(fieldValue)
    else
      fieldValue

  entity: (entityType, data, complete = false) ->
    entityType          = Travis.Entities[entityType] if typeof(entityType) == 'string'
    entity              = null
    for indexKey in entityType.index
      if index          = data[indexKey]
        entity         ?= @_entity(entityType, indexKey, index)
        store           = @_entityData(entityType, indexKey, index)
        store.complete  = true if complete
        store.data[key] = @_parseField(key, value) for key, value of data
    entity

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
