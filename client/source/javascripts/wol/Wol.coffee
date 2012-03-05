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
		return

	unbind: (name, callback) ->
		return if !@e
		if arguments.length is 0
			@e = {}
			return

		return if !@e[name]

		if !callback
			delete @e[name]
			return

		index = @e[name].indexOf callback
		@e[name].splice index, 1
		return

	trigger: (name, data) ->
		return if !@e
		return if !@e[name]
		@e[name].forEach (event) ->
			event data if event?

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

	constructor: (options) ->
		window.implement this, options
		@init options

	set: (props) ->
		@model or= new Wol.Models.Model
		@model.set props
		this

	get: (name) ->
		@model or= new Wol.Models.Model
		@model.get name

class Wol.Collections.Collection extends Wol.Events.EventDispatcher

	constructor: (collections) ->
		@collections = []
		@total = 0
		return if collections is undefined
		return if collections.length is undefined
		return

	add: (params) ->
		if params instanceof Array
			params.forEach (item) ->
				@collections.push item
				return
			return
		item = params
		@collections.push item
		return this

	find: (callback) ->
		result = @collections.filter callback
		result[0]
