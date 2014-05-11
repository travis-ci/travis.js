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
