class Travis.Entity
  @_setup = ->
    defineAttribute = (attr) =>
      console.log(attr)
      @::[attr]    ?= (callback) -> @attribute(attr, callback)
    defineAttribute(attribute) for attribute in @::attributeNames     if @::attributeNames?
    defineAttribute(attribute) for attribute of @::computedAttributes if @::computedAttributes?

  constructor: (session, store) ->
    @session = session
    @_store  = store
    @_setup()

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
        return false if data[@session._clientName(attribute)] == undefined
    return true

  attributes: (list..., callback) ->
    if typeof(callback) == 'string'
      list.push(callback)
      callback = null

    if list.length == 0
      list = @attributeNames
      if @computedAttributes?
        list.push(key) for key, value of @computedAttributes

    if @complete(false) or @hasAttributes(list...)
      promise = new Travis.Promise (p) => p.succeed @_attributes(list)
    else
      promise = @_fetch().wrap =>
        @_store().complete = true
        @_attributes(list)
    promise.then(callback)

  attribute: (name, callback) ->
    @attributes(name).wrap((a) -> a[name]).then(callback)

  _setup: ->

  _attributes: (list) ->
    data    = @_store().data
    result  = {}
    compute = {}
    for name in list
      if computation = @computedAttributes?[name]
        compute[name] = computation
      else
        result[name] = data[@session._clientName(name)]
    for key, value of compute
      result[key] = value.compute(data)
    result

  _cache: (bucket..., key, callback) ->
    cache               = @_store().cache
    cache[bucket]      ?= {}
    cache[bucket][key] ?= callback.call(this)
