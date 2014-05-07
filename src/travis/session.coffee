class Travis.Session
  constructor: (options = {}) ->
    options = { url: Travis.endpoints[options] || options } if typeof(options) == 'string'
    @http   = new Travis.HTTP
      base: options.url || Travis.endpoints.default
      headers:
        "Accept":     "application/vnd.travis-ci.2+json"
        "User-Agent": "travis.js/#{Travis.version} #{Travis.System.info()}"

  config: (callback) ->
    @_config ?= @http.get('/config').wrap (response) -> response.body.config
    @_config.then(callback)

  github: (callback) ->
    @_github ?= Travis.Promise.delegate 'get', 'head', 'post', 'put', 'patch', 'delete', 'request', (promise) =>
      @config (c) =>
        client = new Travis.HTTP base: c.github.api_url, headers: { "User-Agent": @http.defaultHeaders["User-Agent"] }
        promise.succeed(client)
    @_github.then(callback)
