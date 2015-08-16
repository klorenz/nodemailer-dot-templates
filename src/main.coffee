{keys, extend} = require "underscore"

class UnresolvableData extends Error
  constructor: (@message, {@templateHandler, @options, @templates, @templateData}) ->
    super

# createTemplate even if eval is not allowed as in atom
createTemplate = (source) ->
  try
    eval "1;"
    doT = require "dot"
    doT.template source

  catch
    {allowUnsafeNewFunction, allowUnsafeEval} = loophole = require 'loophole'

    allowUnsafeEval ->
      allowUnsafeNewFunction ->
        doT = require "dot"
        doT.template source

doT = (options) ->
  templater = new TemplateManager options

  (options, done) ->
    templater.applyTemplates options, done


class TemplateManager

  constructor: (options) ->
    options ?= {}
    @useStrictVars      = options.useStrictVars ? false
    @useAllData         = options.useAllData ? true
    @templateDataName   = options.templateDataName ? 'DATA'
    @handleUnresolvable = options.handleUnresolvable

  applyTemplates: (options, done) ->
    templates = {}
    templateData = extend {}, options[@templateDataName] or {}

    for key, value of options
      console.log "option", key, value
      continue unless typeof value is "string"

      if not value.match /\{\{/
        if @useAllData
          if key not of templateData
            templateData[key] = value
      else
        source = value
        if not @useStrictVars
          source = value.replace /\{\{\w+\}\}/g, (m) -> "{{=it."+m.substring(2)

        templates[key] = {
          source:     value
          template:   createTemplate(source)
          undefCount: (value.match(/undefined/g) or []).length
        }

    (new TemplateHandler @, templates, templateData).process options, done


class TemplateHandler
  constructor: (@config, @templates, @templateData) ->

  rendered: (key) ->
    if typeof @templates[key] is "string"
      @templates[key]
    else if typeof @templates[key] is "function"
      @templates[key].call this, @templateData
    else
      @templates[key].template(@templateData)

  handleTemplate: (key) ->
    value = @rendered key

    console.log "value", value

    if @config.useAllData
      undefCount = (value.match(/undefined/g) or []).length

      # check if template has been resolved completely
      if undefCount == 0 or undefCount == @templates[key].undefCount
        delete @templates[key]
        @templateData[key] = value
        return value

      else
        throw new Error "cannot resolve #{key}"

    else
      delete @templates[key]
      return value

  process: (options, done) ->
    currentTemplateCount = keys(@templates).length

    debugger

    while keys(@templates).length

      for key in keys(@templates)
        try
          options[key] = @handleTemplate key, false
        catch e
          # console.warn e.message

      if currentTemplateCount == keys(@templates).length
        break

      currentTemplateCount = keys(@templates).length

    if currentTemplateCount > 0
      # not all templates could be applied
      # this is may be an error or the text
      # 'undefined' has been inserted into

      if @config.handleUnresolvable is 'error'
        return done new UnresolvableData "Cannot resolve "+keys(@templates).join(", "), {templateHandler: this, options, @templates, @templateData}

      else if @config.handleUnresolvable
        return @config.handleUnresolvable.call this, options, @templates, @templateData, done

      else
        for key in keys(@templates)
          options[key] = @rendered key
    done()


module.exports = {doT}
