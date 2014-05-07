class Travis.Session
  constructor: (options = {}) ->
    options = { url: Travis.endpoints[options] || options } if typeof(options) == 'string'
    @http   = new Travis.HTTP
      base: options.url || Travis.endpoints.default
      headers: { "Accept": "application/vnd.travis-ci.2+json" }

  config: (callback) ->
    @_config ?= @http.get('/config').wrap (response) -> response.body.config
    @_config.then(callback)

  github: (callback) ->
    @_github ?= @config().wrap (config) -> new Travis.HTTP(base: config.github.api_url)
    @_github.then(callback)
