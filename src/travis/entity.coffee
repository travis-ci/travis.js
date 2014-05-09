class Travis.Entity
  constructor: (session, store) ->
    @session = session
    @_store  = store

  complete: (checkAttributes = true) ->
    return true unless @_fetch?
    return true if checkAttributes and @attributeNames? and @hasAttributes()
    @_store().complete

  hasAttributes: (list...) ->
    list = @attributeNames if list.length == 0
    data = @_store().data
    for attribute in list
      if dependsOn = @computedAttributes?[attribute]?.dependsOn
        return false unless @hasAttributes(dependsOn...)
      else
        return false if data[@_apiName(attribute)] == undefined
    return true

  attributes: (list..., callback) ->
    list.push(callback) if typeof(callback) == 'string'

    if list.length == 0
      list = @attributeNames
      if @computedAttributes?
        list.push(key) for key, value of @computedAttributes

    if @complete(false) or @hasAttributes(list...)
      promise = new Travis.Promise (p) => p.succeed @_attributes(list)
    else
      promise = @_fetch().wrap => @_attributes(list)
    promise.then(callback)

  _attributes: (list) ->
    data    = @_store().data
    result  = {}
    compute = {}
    for name in list
      if computation = @computedAttributes?[name]
        compute[name] = computation
      else
        result[name] = data[@_apiName(name)]
    for key, value of compute
      result[key] = value.compute(data)
    result

  _clientName: (string) -> string.replace /_([a-z])/g, (g) -> g[1].toUpperCase()
  _apiName:    (string) -> string.replace /[A-Z]/g, (g) -> "_" + g[0].toLowerCase()
