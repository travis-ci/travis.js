Travis = require('../support') unless Travis?

describe 'Travis.HTTP', ->
  beforeEach ->
    @http = new Travis.HTTP base: "https://api.travis-ci.org"

  describe 'get', ->
    it 'triggers http calls', (done) ->
      @http.get '/', (response) ->
        expect(response.status).toBe(200)
        expect(response.body.hello).toBe('world')
        done()

    it 'follows redirects', (done) ->
      @http.get '/redirect?to=https%3A%2F%2Fapi%2Etravis%2Dci%2Eorg%2F', (response) ->
        expect(response.status).toBe(200)
        expect(response.body.hello).toBe('world')
        done()