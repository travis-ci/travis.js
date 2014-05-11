'use strict'

Travis                    = (options) -> new Travis.Session(options)
Travis.version            = '0.1.1'
Travis.endpoints          = org: 'https://api.travis-ci.org', pro: 'https://api.travis-ci.com'
Travis.endpoints.default  = Travis.endpoints.org
Travis.callbacks          = {}
Travis.globalCallbacks    = []
Travis.callbacksFor       = (event) -> Travis.globalCallbacks.concat(Travis.callbacks[event] || [])
Travis.notify             = (event, payload) -> callback(data: payload, type: event) for callback in Travis.callbacksFor(event)
Travis.debug              = -> Travis.on (e) -> console.log(e.type, e.data)

Travis.on = (events..., callback) ->
  if events.length == 0
    Travis.globalCallbacks.push(callback)
  else
    for event in events
      Travis.callbacks[event] = [] unless Travis.callbacks[event]?
      Travis.callbacks[event].push(callback)

Travis._setup  = ->
  for name, entity of Travis.Entity
    entity._setup() if entity._setup?
  Travis._setup = ->

module.exports = Travis if module?
window.exports = Travis if window?
@Travis        = Travis
