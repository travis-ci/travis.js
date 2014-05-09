if require?
  require('source-map-support').install();
  Travis = module.exports = require('../build/travis')

jasmine.DEFAULT_TIMEOUT_INTERVAL = 15000

# Travis.debug()

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

Travis = require('../support') unless Travis?

describe 'Travis.HTTP', ->
  beforeEach ->
    @http = new Travis.HTTP
      base: "https://api.travis-ci.org"
      headers: { "Accept": "application/vnd.travis-ci.2+json" }

  describe 'get', ->
    it 'triggers http calls', (done) ->
      @http.get '/', (response) ->
        expect(response.status).toBe(200)
        expect(response.body.hello).toBe('world')
        done()

  describe 'prepareRequest', ->
    safeMethod = (method) =>
      describe "#{method} requests", ->
        it 'adds query parameters from a string', ->
          request = @http.prepareRequest method, '/', 'foo'
          expect(request.url).toBe('https://api.travis-ci.org/?foo')
        it 'adds query parameters from an object', ->
          request = @http.prepareRequest method, '/example', foo: 'bar', bar: 'baz'
          expect(request.url).toBe('https://api.travis-ci.org/example?foo=bar&bar=baz')
        it 'respects and existing query string', ->
          request = @http.prepareRequest method, '/?foo=bar', bar: 'baz'
          expect(request.url).toBe('https://api.travis-ci.org/?foo=bar&bar=baz')
        it 'escapes special characters', ->
          request = @http.prepareRequest method, '/?foo=bar', bar: 'b&z/a'
          expect(request.url).toBe('https://api.travis-ci.org/?foo=bar&bar=b%26z%2Fa')
        it 'does not escape a query string', ->
          request = @http.prepareRequest method, '/', 'foo=bar'
          expect(request.url).toBe('https://api.travis-ci.org/?foo=bar')

    unsafeMethod = (method) =>
      describe "#{method} requests", ->
        it 'does not add query parameters from a string', ->
          request = @http.prepareRequest method, '/', 'foo'
          expect(request.url).toBe('https://api.travis-ci.org/')
        it 'sets the body from a string', ->
          request = @http.prepareRequest 'POST', '/', 'foo'
          expect(request.body).toBe('foo')
        it 'generates a JSON body from an object', ->
          request = @http.prepareRequest 'POST', '/', foo: 'bar'
          expect(request.headers['Content-Type']).toBe('application/json')
          expect(JSON.parse(request.body).foo).toBe('bar')

    safeMethod   'GET'
    safeMethod   'HEAD'
    unsafeMethod 'POST'
    unsafeMethod 'PUT'
    unsafeMethod 'PATCH'
    unsafeMethod 'DELETE'
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

Travis = require('../support') unless Travis?

describe 'Travis.Session', ->
  describe 'constructor', ->
    it 'defaults to api.travis-ci.org', ->
      session = new Travis()
      expect(session.http.base).toBe('https://api.travis-ci.org')

    it 'resolves pro to the proper host', ->
      session = new Travis('pro')
      expect(session.http.base).toBe('https://api.travis-ci.com')

    it 'takes a URL as argument', ->
      session = new Travis('https://api-staging.travis-ci.org')
      expect(session.http.base).toBe('https://api-staging.travis-ci.org')

    it 'takes an object as argument', ->
      session = new Travis(url: 'https://api-staging.travis-ci.org')
      expect(session.http.base).toBe('https://api-staging.travis-ci.org')