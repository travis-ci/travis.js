Travis.Delegator =
  define: (methods..., caller, constructor) ->
    @eachMethod methods..., (method) => @delegate(caller, constructor, method)

  defineNested: (methods..., caller, constructor) ->
    @eachMethod methods..., (method) => @delegateNested(caller, constructor, method)

  defineSimple: (methods..., caller, constructor) ->
    @eachMethod methods..., (method) => @delegateSimple(caller, constructor, method)

  eachMethod: (methods..., callback) ->
    for method in methods
      if typeof(method) == 'string'
        callback(method)
      else if method.delegationMethods
        callback(subMethod) for subMethod in method.delegationMethods()
      else if method.prototype?
        callback(subMethod) for subMethod of method.prototype
      else
        callback(subMethod) for subMethod of method

  delegate: (caller, constructor, method) ->
    return if method.indexOf('_') == 0
    constructor[method] = (args..., callback) ->
      if typeof(callback) == 'function'
        constructor[method].apply(this, args).then(callback)
      else
        args.push(callback)
        outerPromise = if constructor.then? then constructor else constructor.call(caller)
        new Travis.Promise (delegationPromise) ->
          outerPromise.then (outerResult) ->
            innerPromise = outerResult[method].apply(outerResult, args)
            innerPromise.then (innerResult) -> delegationPromise.succeed(innerResult)
            innerPromise.catch (innerError) -> delegationPromise.fail(innerError)
          outerPromise.catch (outerError)   -> delegationPromise.fail(outerError)

  delegateNested: (caller, constructor, method) ->
    constructor[method] = (args...) ->
      constructor.call caller, (result) ->
        result[method].call(result, args...)

  delegateSimple: (caller, constructor, method) ->
    constructor[method] = constructor.call(caller)[method]