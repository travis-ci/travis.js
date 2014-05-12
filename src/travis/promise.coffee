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