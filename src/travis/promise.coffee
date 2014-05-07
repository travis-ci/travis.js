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