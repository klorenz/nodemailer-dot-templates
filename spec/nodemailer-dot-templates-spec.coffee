{doT} = require "../src/main.coffee"
{clone, keys} = require "underscore"

describe 'nodemailer-dot-templates', ->

  describe 'useStrictVars', ->
    options = null
    done = null


    beforeEach ->
      options = {foo: 'hello {{easy}}', bar: 'hello {{=it.easy}}', easy: 'world'}
      done = false


    it 'can handle non strict variable names (default)', ->
      dot = doT()

      dot options, ->
        expect(options).toEqual { foo: 'hello world', bar: 'hello world', easy: 'world' }
        done = true

      waitsFor -> done


    it 'can handle variable names strictly', ->
      dot = doT useStrictVars: on
      options = {bar: 'hello {{=it.easy}}', easy: 'world'}

      dot options, ->
        expect(options).toEqual {bar: 'hello world', easy: 'world'}
        done = true

      waitsFor -> done


  describe 'useAllData - use all data from options as input (default)', ->
    options = null
    done = null

    beforeEach ->
      options = {foo: 'hello {{easy}} {{cc}}', cc: "vader@death-star.gov", DATA: {easy: 'world'}}
      done = false


    it 'can handle all data', ->
      dot = doT()

      dot options, ->
        expect(options).toEqual {foo: 'hello world vader@death-star.gov', cc: "vader@death-star.gov", DATA: {easy: 'world'}}
        done = true

      waitsFor -> done


    it 'can handle Template data only', ->
      dot = doT useAllData: false

      dot options, ->
        expect(options).toEqual {foo: 'hello world undefined', cc: "vader@death-star.gov", DATA: {easy: 'world'}}
        done = true

      waitsFor -> done

    it 'can raise an error, if not all data could be expanded', ->
      dot = doT handleUnresolvable: 'error'

      options.foo = 'hello {{easy}} {{x}}'

      dot options, (err) ->
        expect(keys(err.templates)).toEqual ['foo']
        done = true

      waitsFor -> done

    it 'can raise an error, by mistake, assuming not all data could be expanded', ->
      dot = doT handleUnresolvable: 'error'

      options.foo = 'hello {{easy}} undefined'
      options.DATA.easy = 'world undefined'

      dot options, (err) ->
        expect(keys(err.templates)).toEqual ['foo']
        done = true

      waitsFor -> done
