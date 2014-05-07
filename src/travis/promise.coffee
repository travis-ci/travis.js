class Travis.Promise
  @delegate: (methods..., closure) ->
    (new this(closure)).delegate(methods...)

  delegate: (methods...) ->
    for method in methods
      if typeof(method) == 'string'
        @delegateMethod(method, method)
      else
        @delegateMethod(from, to) for from, to of method
    return this

  delegateMethod: (from, to) ->
    this[from] ?= (args..., callback) =>
      if typeof(callback) == 'function'
        promise = this[from](args...)
        promise.then(callback)
      else
        args.push(callback)
        new Travis.Promise (p) =>
          console.log('promise:delegate', from, to, args)
          @onSuccess (payload) -> payload[to](args...).then(p.succeed, p.fail)
          @onFailure (payload) -> p.fail(payload)
          @run()
    return this

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
    console.log(this)
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