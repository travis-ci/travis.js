Travis.Delegator =
  define: (caller, constructor, methods...) ->
    for method in methods
      constructor[method] = @delegator(caller, constructor, method)

  delegator: (caller, constructor, method) ->
    (args..., callback) ->
      if typeof(callback) == 'function'
        constructor[method].apply(this, args).then(callback)
      else
        args.push(callback)
        outerPromise = constructor.call(caller)
        new Travis.Promise (delegationPromise) ->
          outerPromise.then (outerResult) ->
            innerPromise = outerResult[method].apply(outerResult, args)
            innerPromise.then (innerResult) -> delegationPromise.succeed(innerResult)
            innerPromise.catch (innerError) -> delegationPromise.fail(innerError)
          outerPromise.catch (outerError)   -> delegationPromise.fail(outerError)
