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