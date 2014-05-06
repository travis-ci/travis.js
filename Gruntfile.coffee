chalk    = require 'chalk'
coffee   = require 'coffee-script'
replace  = (options) ->
  result = ''
  source = options.source
  format = options.formatRest || (e) -> e
  while source.length > 0
    if match  = source.match(options.pattern)
      result += format source.slice(0, match.index)
      result += if typeof(options.with) == 'function' then options.with(match) else options.with
      source  = source.slice(match.index + match[0].length)
    else
      result += format source
      source  = ''
  result

module.exports = (grunt) ->
  browsers =
    sl_chrome:
      base: 'SauceLabs'
      browserName: 'chrome'
      platform: 'Windows 7'
    sl_firefox:
      base: 'SauceLabs',
      browserName: 'firefox'
      version: '27'
    sl_ie_11:
      base: 'SauceLabs'
      browserName: 'internet explorer'
      platform: 'Windows 8.1'
      version: '11'

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    coffee:
      compile:
        options: { bare: true, sourceMap: true, join: true, joinExt: '.coffee' }
        files:
          'build/travis.js': ['src/travis.coffee', 'src/travis/*.coffee', 'src/travis/*/*.coffee']
          'build/travis.spec.js': ['spec/*.coffee', 'spec/travis/*.coffee']

    uglify:
      options:
        mangle: false
        sourceMap: true
        sourceMapIn: 'build/travis.js.map'
        sourceMapName: 'build/travis.min.js.map'
      build:
        src:  'build/travis.js'
        dest: 'build/travis.min.js'

    watch:
      files: ['{src,spec}/**/*.coffee', '*.coffee.md']
      tasks: ['build']

    jasmine_node:
      options: { extensions: 'coffee' },
      all: ['spec/']

    karma:
      options:
        basePath: 'build'
        frameworks: ['jasmine']
        files: ['travis.js', 'travis.spec.js']
        reporters: 'dots'
        port: 9876
        colors: true
        autoWatch: false
        singleRun: true
      chrome:
        browsers: ['Chrome']
      firefox:
        browsers: ['Firefox']
      safari:
        browsers: ['Safari']
      dev:
        browsers: ['Chrome', 'Firefox', 'Safari']
      sauce:
        sauceLabs:
          testName: 'travis.js'
        customLaunchers: browsers
        browsers: Object.keys(browsers)
        reporters: ['dots', 'saucelabs']

  grunt.registerTask 'readme', 'generate JS readme', ->
    formatCoffee = (source) ->
      source = replace(source: coffee.compile(source, bare: true), pattern: /return /, with: '')
      source = replace(source: source, pattern: /\n\n(\w+ = [^\n]+)/, with: (m) -> "\n#{m[1]}")
      source

    result = replace
      source:     grunt.file.read 'README.coffee.md'
      pattern:    /\n``` *coffee *\n([^`]+)\n```\n/m
      with:       (match) -> "\n``` javascript\n#{formatCoffee(match[1])}```"
      formatRest: (rest)  -> replace(source: rest, pattern: /CoffeeScript/, with: 'JavaScript')

    grunt.file.write 'README.md', result
    grunt.log.writeln('File ' + chalk.cyan('README.md') + ' created.');

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-jasmine-node'
  grunt.loadNpmTasks 'grunt-karma'

  grunt.registerTask 'spec',    ['build', 'jasmine_node']
  grunt.registerTask 'build',   ['coffee', 'uglify', 'readme']
  grunt.registerTask 'default', ['spec', 'karma:dev']

  grunt.registerTask 'ci:node',  ['spec']
  grunt.registerTask 'ci:sauce', ['build', 'karma:sauce']
