Travis.System =
  info: ->
    if navigator?.userAgent?
      navigator.userAgent
    else if process?
      "node/#{process.versions.node} (#{process.platform}) v8/#{process.versions.v8}"
    else
      'unknown'
