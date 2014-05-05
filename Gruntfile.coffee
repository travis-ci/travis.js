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
      files: ['{src,spec}/**/*.coffee']
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
      dev:
        browsers: ['Chrome', 'Firefox']
      sauce:
        sauceLabs:
          testName: 'travis.js'
        customLaunchers: browsers
        browsers: Object.keys(browsers)
        reporters: ['dots', 'saucelabs']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-jasmine-node'
  grunt.loadNpmTasks 'grunt-karma'

  grunt.registerTask 'spec',    ['build', 'jasmine_node']
  grunt.registerTask 'build',   ['coffee', 'uglify']
  grunt.registerTask 'default', ['spec', 'karma:dev']

  grunt.registerTask 'ci:node',  ['spec']
  grunt.registerTask 'ci:sauce', ['build', 'karma:sauce']
