if module?
  Travis = require '../support'
  fs     = require 'fs'

  class Response
    constructor: (request, response, next) ->
      @request  = request
      @response = response
      @next     = next

    redirect: (location) ->
      @response.writeHead 302, location: "#{Travis.Spec.baseURL}#{location}"
      @response.end()

    payload: (name) ->
      @response.setHeader 'Content-Type', 'application/json'
      fs.readFile "spec/support/payloads/#{name}.json", encoding: 'utf-8', (error, data) =>
        throw error if error?
        @response.end data

    dispatch: ->
      switch @request.url
        when '/'         then @redirect('/spec/runner.html')
        when '/hello'    then @payload('hello_world')
        when '/redirect' then @redirect('/hello')
        else @next()

  module.exports = (request, response, next) ->
    response = new Response(request, response, next)
    response.dispatch()
