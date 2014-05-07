if require?
  require('source-map-support').install();
  Travis = module.exports = require('../build/travis')

jasmine.DEFAULT_TIMEOUT_INTERVAL = 15000

# Travis.debug()
