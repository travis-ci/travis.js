class Travis.Session
  constructor: (options = {}) ->
    options                  = { url: Travis.endpoints[options] || options } if typeof(options) == 'string'
    @_options                = options
    headers                  = { "Accept": "application/vnd.travis-ci.2+json" }
    headers['Authorization'] = "token #{options.token}" if options.token?
    @http                    = new Travis.HTTP(headers: headers, base: options.url || Travis.endpoints.default)

    Travis.Delegator.define this, @github, 'get'

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
