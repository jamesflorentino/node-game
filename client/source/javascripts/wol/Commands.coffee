@Wol

class Wol.Models.Command extends Wol.Models.Model
	init: ->
		return throw 'command code unspecified' if !@get('code')
		return throw 'command name unspecified' if !@get('name')
		props = {}
		props.radius = 1 if !@get('radius')
		props.type = 'radius' if !@get('type')
		props.id = @get 'code'
		@set props
		return


class Wol.Models.Commands extends Wol.Models.Model

	init: ->
		@list = []
		return

	add: (data) ->
		command = new Wol.Models.Command data
		@list.push command
		return
	
	getCommands: ->
		@list



