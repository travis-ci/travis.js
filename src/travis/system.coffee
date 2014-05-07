Travis.System =
  info: ->
    if navigator?.userAgent?
      navigator.userAgent
    else if process?
      "node/#{process.versions.node} (#{process.platform}) v8/#{process.versions.v8}"
    else
      'unknown'

  base64: (string) ->
    if Buffer?
      new Buffer(string).toString('base64')
    else
      btoa(string)