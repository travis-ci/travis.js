class Travis.Entities.Repository extends Travis.Entity
  @one:  ['repo', 'repository']
  @many: ['repos', 'permissions', 'admin', 'pull', 'push', 'hooks']

  attributeNames: [
    "id", "slug", "description", "last_build_id", "last_build_number", "last_build_state",
    "last_build_duration", "last_build_started_at", "last_build_finished_at", "github_language"
  ]