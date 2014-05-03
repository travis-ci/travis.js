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
