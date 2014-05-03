Travis = require('../support') unless Travis?

describe 'Travis.HTTP', ->
  beforeEach ->
    @http = new Travis.HTTP base: Travis.Spec.baseURL

  describe 'get', ->
    it 'triggers http calls', (done) ->
      @http.get '/hello', (response) ->
        expect(response.status).toBe(200)
        expect(response.body.hello).toBe('world')
        done()

    it 'follows redirects', (done) ->
      @http.get '/redirect', (response) ->
        expect(response.status).toBe(200)
        expect(response.body.hello).toBe('world')
        done()