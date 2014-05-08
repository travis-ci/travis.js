Travis = require '../../build/travis' unless Travis?
travis = new Travis
travis.repositories (repos) ->
  for repo in repos
    repo.attributes (r) ->
      info = "repository #{r.slug}: #{r.lastBuildState}"
      if document? then document.writeln(info + "<br>") else console.log(info)