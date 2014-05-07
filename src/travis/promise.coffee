class Travis.Promise
  constructor: (closure) ->
    @onSuccess = []
    @onFailure = []
    @data      = null
    @closure   = closure
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
    callback(@data) for callback in @onSuccess
    @onSuccess = []
    @onFailure = []
    return this

  fail: (data) ->
    @setState('failed', data)
    Travis.notify('promise:fail', data)
    callback(@data) for callback in @onFailure
    @onSuccess = []
    @onFailure = []
    return this

  onSuccess: (callback) ->
    @then(callback, false, false)

  wrap: (wrapper) ->
    wrapped = this
    promise = new Travis.Promise -> wrapped.run()
    @then ((input) -> promise.succeed wrapper(input)), ((input) -> promise.fail(input)), false
    promise

  then: (callback, errback, trigger = null) ->
    trigger = (callback? or errback?) if trigger == null
    if @succeeded
      callback(@data) if callback?
    else if @failed
      errback(@data) if errback?
    else
      @onSuccess.push callback if callback?
      @onFailure.push errback  if errback?
      @run() if trigger
    return this

  catch: (errback) ->
    @then(null, errback)
    return this