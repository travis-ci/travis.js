if require?
  require('source-map-support').install();
  Travis = module.exports = require('../build/travis')

Travis.Spec =
  baseURL: window?.location?.origin || "http://localhost:#{process?.env?.port || 9595}"

# Travis.endpoints.default = Travis.Spec.baseURL
# Travis.debug()
