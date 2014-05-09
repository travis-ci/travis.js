var Travis;

if (typeof require !== "undefined" && require !== null) {
  require('source-map-support').install();
  Travis = module.exports = require('../build/travis');
}

jasmine.DEFAULT_TIMEOUT_INTERVAL = 15000;

if (Travis == null) {
  Travis = require('./support');
}

describe('Travis', function() {
  var expectedVersion;
  expectedVersion = '0.1.0';
  it("has version " + expectedVersion, function() {
    expect(Travis.version).toBe(expectedVersion);
    if (typeof require !== "undefined" && require !== null) {
      expect(require('../package.json').version).toBe(expectedVersion);
      return expect(require('../bower.json').version).toBe(expectedVersion);
    }
  });
  return it('can subscribe to global events', function(done) {
    Travis.on('example', function(event) {
      expect(event.data).toBe(42);
      expect(event.type).toBe('example');
      return done();
    });
    return Travis.notify('example', 42);
  });
});

if (Travis == null) {
  Travis = require('../support');
}

describe('Travis.HTTP', function() {
  beforeEach(function() {
    return this.http = new Travis.HTTP({
      base: "https://api.travis-ci.org",
      headers: {
        "Accept": "application/vnd.travis-ci.2+json"
      }
    });
  });
  describe('get', function() {
    return it('triggers http calls', function(done) {
      return this.http.get('/', function(response) {
        expect(response.status).toBe(200);
        expect(response.body.hello).toBe('world');
        return done();
      });
    });
  });
  return describe('prepareRequest', function() {
    var safeMethod, unsafeMethod;
    safeMethod = (function(_this) {
      return function(method) {
        return describe("" + method + " requests", function() {
          it('adds query parameters from a string', function() {
            var request;
            request = this.http.prepareRequest(method, '/', 'foo');
            return expect(request.url).toBe('https://api.travis-ci.org/?foo');
          });
          it('adds query parameters from an object', function() {
            var request;
            request = this.http.prepareRequest(method, '/example', {
              foo: 'bar',
              bar: 'baz'
            });
            return expect(request.url).toBe('https://api.travis-ci.org/example?foo=bar&bar=baz');
          });
          it('respects and existing query string', function() {
            var request;
            request = this.http.prepareRequest(method, '/?foo=bar', {
              bar: 'baz'
            });
            return expect(request.url).toBe('https://api.travis-ci.org/?foo=bar&bar=baz');
          });
          it('escapes special characters', function() {
            var request;
            request = this.http.prepareRequest(method, '/?foo=bar', {
              bar: 'b&z/a'
            });
            return expect(request.url).toBe('https://api.travis-ci.org/?foo=bar&bar=b%26z%2Fa');
          });
          return it('does not escape a query string', function() {
            var request;
            request = this.http.prepareRequest(method, '/', 'foo=bar');
            return expect(request.url).toBe('https://api.travis-ci.org/?foo=bar');
          });
        });
      };
    })(this);
    unsafeMethod = (function(_this) {
      return function(method) {
        return describe("" + method + " requests", function() {
          it('does not add query parameters from a string', function() {
            var request;
            request = this.http.prepareRequest(method, '/', 'foo');
            return expect(request.url).toBe('https://api.travis-ci.org/');
          });
          it('sets the body from a string', function() {
            var request;
            request = this.http.prepareRequest('POST', '/', 'foo');
            return expect(request.body).toBe('foo');
          });
          return it('generates a JSON body from an object', function() {
            var request;
            request = this.http.prepareRequest('POST', '/', {
              foo: 'bar'
            });
            expect(request.headers['Content-Type']).toBe('application/json');
            return expect(JSON.parse(request.body).foo).toBe('bar');
          });
        });
      };
    })(this);
    safeMethod('GET');
    safeMethod('HEAD');
    unsafeMethod('POST');
    unsafeMethod('PUT');
    unsafeMethod('PATCH');
    return unsafeMethod('DELETE');
  });
});

if (Travis == null) {
  Travis = require('../support');
}

describe('Travis.Promise', function() {
  it('executes functions passed to then if succeeded', function(done) {
    var promise;
    promise = new Travis.Promise;
    promise.succeed(42);
    return promise.then(function(value) {
      expect(value).toBe(42);
      return done();
    });
  });
  return it('executes then functions passed to then right away if already succeeded', function() {
    var promise, value;
    promise = new Travis.Promise;
    value = 23;
    promise.succeed(42);
    promise.then(function(data) {
      return value = data;
    });
    return expect(value).toBe(42);
  });
});

if (Travis == null) {
  Travis = require('../support');
}

describe('Travis.Session', function() {
  return describe('constructor', function() {
    it('defaults to api.travis-ci.org', function() {
      var session;
      session = new Travis();
      return expect(session.http.base).toBe('https://api.travis-ci.org');
    });
    it('resolves pro to the proper host', function() {
      var session;
      session = new Travis('pro');
      return expect(session.http.base).toBe('https://api.travis-ci.com');
    });
    it('takes a URL as argument', function() {
      var session;
      session = new Travis('https://api-staging.travis-ci.org');
      return expect(session.http.base).toBe('https://api-staging.travis-ci.org');
    });
    return it('takes an object as argument', function() {
      var session;
      session = new Travis({
        url: 'https://api-staging.travis-ci.org'
      });
      return expect(session.http.base).toBe('https://api-staging.travis-ci.org');
    });
  });
});

//# sourceMappingURL=travis.spec.js.map
