Travis = require('./support') unless Travis?

describe 'Travis', ->

  expectedVersion = '0.1.0'
  it "has version #{expectedVersion}", ->
    expect(Travis.version).toBe(expectedVersion)
    if require?
      expect(require('../package.json').version).toBe(expectedVersion)
      expect(require('../bower.json').version).toBe(expectedVersion)

  it 'can subscribe to global events', (done) ->
    Travis.on 'example', (event) ->
      expect(event.data).toBe(42)
      expect(event.type).toBe('example')
      done()

    Travis.notify 'example', 42
