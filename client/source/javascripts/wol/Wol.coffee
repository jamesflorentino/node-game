# =====================================================
# Main Wol App
# =====================================================
@Wol =
  Models: {}
  Collections: {}
  Views: {}
  Events: {}
  Ui: {}

## A class that enables event dispatchment and bindings
class Wol.Events.EventDispatcher

  bind: (name, callback) ->
    @e or= {}
    @e[name] or= []
    @e[name].push callback
    this

  unbind: (name, callback) ->
    return this if !@e
    if arguments.length is 0
      @e = {}
      return this

    return this if !@e[name]

    if !callback
      delete @e[name]
      return this

    index = @e[name].indexOf callback
    @e[name].splice index, 1
    return this

  trigger: (name, data) ->
    return this if !@e
    return this if !@e[name]
    @e[name].forEach (event) ->
      event data if event?
    this

## A basic data structure for the app
class Wol.Models.Model extends Wol.Events.EventDispatcher
  
  constructor: (options) ->
    @attributes = {}
    @id = "".randomId()
    window.implement(@attributes, options) if options?
    @init options

  init: (options) ->
    return

  set: (props) ->
    window.implement(@attributes, props)
    this

  get: (name) ->
    @attributes or= {}
    @attributes[name]


class Wol.Views.View extends Wol.Events.EventDispatcher

  model: new Wol.Models.Model()
  constructor: (options) ->
    @model = new Wol.Models.Model()
    window.implement this, options
    @init options

  set: (props) ->
    @model or= new Wol.Models.Model()
    @model.set props
    this

  get: (name) ->
    @model or= new Wol.Models.Model()
    @model.get name

class Wol.Collections.Collection extends Wol.Events.EventDispatcher

  collections: []
  total: []
  constructor: (collections) ->
    @collections = []
    @total = 0
    return if collections is undefined
    return if collections.length is undefined
    return

  __addToList: (item) ->
    if item instanceof Wol.Models.Model
      @collections.push item
    else
      @collections.push new Wol.Models.Model(item)
    @total = @collections.length

  add: (params) ->
    if params instanceof Array
      params.forEach (item) => @__addToList item
      return
    @__addToList params
    return this

  find: (callback) ->
    result = @collections.filter callback
    result[0]

  each: (callback) -> @collections.each callback
