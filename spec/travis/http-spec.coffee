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