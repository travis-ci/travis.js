Travis = require('../support') unless Travis?

describe 'Travis.Promise', ->
  it 'executes functions passed to then if succeeded', (done) ->
    promise = new Travis.Promise
    promise.succeed(42)
    promise.then (value) ->
      expect(value).toBe(42)
      done()

  it 'executes then functions passed to then right away if already succeeded', ->
    promise = new Travis.Promise
    value   = 23
    promise.succeed(42)
    promise.then (data) -> value = data
    expect(value).toBe(42)
