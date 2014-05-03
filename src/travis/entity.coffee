class Travis.Entity
  @one:  []
  @many: []

  attributeNames: []

  constructor: (session, data, promise) ->
    data     = { id: data } if typeof(data) == "number"
    @_data   = data || {}
    @session = session
    @promise = promise

    if @promise
      @promise.onSuccess (data) ->
        data = data._data if data._data?
        @_data[key] = value for key, valye of data
    else
      @promise = new Travis.Promise()
      @promise.succeed(@_data)

  hasAttributes: (attributeNames...) ->
    attributeNames = @attributeNames if attributeNames.length == 0
    for attributeName in attributeNames
      return false if @_data[attributeName] == undefined
    return true

  then: (callback, errback) ->
    @promise.then(callback, errback)
    return this

  catch: (errback) ->
    @promise.catch(errback)
    return this

  attributes: (attributeNames...) ->
    attributeNames = @attributeNames if attributeNames.length == 0
    callbacks      = []
    attributeList  = []
    filterData     = ->
      result       = {}
      result[key]  = @_data[key] for key in attributeList
      result

    for attributeName in attributeNames
      if typeof(attributeName) == 'string'
        throw "unknown attribute #{attributeName}" unless @attributeNames.indexOf(attributeName)
        attributeList.push(attributeName)
      else
        callbacks.push(attributeName)

    if hasAttributes(attributeList)
      promise = new Travis.Promise()
      promise.succeed filterData(@_data)
    else
      promise = new Travis.Promise (p) ->
        @promise.then (-> p.succeed filterData()), ((e) -> p.fail e)

    promise.then(callback) for callback in callbacks
    return promise