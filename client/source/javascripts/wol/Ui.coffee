Ui = Wol.Ui


class Ui.CancelButton extends Wol.Views.View

	init: ->
		@el = $ '#cancelButton'
		@el.click =>
			@trigger 'cancel'
			@hide()
		return

	show: (x, y) ->
		@el.addClass 'active'
		return if x is undefined
		@el.css top: y, left: x

		return

	hide: ->
		@el.removeClass 'active'
		return


class Ui.CommandList extends Wol.Views.View

	init: ->
		@el = $ "#commandList"
		@cancelButton = @el.find '.cancel'
		@list = @el.find '.list'
		@list.empty()
		@tpl = (data) ->
			"<li>
				<span class='index'>#{data.index}</span>
				<span class='command name'>#{data.name}</span>
				<span class='indicator'></span>
			</li>"
		@cancelButton.click =>
			@trigger 'cancel'
			@hide()
		return

	setCommands: (commands) ->
		list = @list
		tpl = @tpl
		list.empty()
		commands.forEach (command, i) =>
			commandName = command.get 'name'
			commandCode = command.get 'code'
			commandView = $ tpl
				index: i + 1
				name: commandName
			commandView.click =>
				@trigger 'act', command
				return
			list.append commandView
		return

	show: (x, y) ->
		@el.removeClass 'hidden'
		@el.css top: y, left: x
		@el.addClass 'active'

		return

	hide: ->
		@el.addClass 'hidden'
		return


class Ui.UnitInfo extends Wol.Views.View

	init: ->
		@el = $ '#unitInfo'
		@hp = @el.find '.health'
		@ep = @el.find '.energy'
		@ap = @el.find '.action'
		@tp = @el.find '.turn'
		@pic = @el.find '.portrait'
		@title = @el.find '.name'
		@hp.data 'oWidth', @hp.find('.bar').width()
		@ep.data 'oWidth', @ep.find('.bar').width()
		@ap.data 'oWidth', @ap.find('.bar').width()
		@tp.data 'oWidth', @tp.find('.bar').width()
		return

	show: (attributes) ->
		@title.text attributes.name
		@updateBar @hp, attributes.health, attributes.maxHealth
		@updateBar @ep, attributes.energy, attributes.maxEnergy
		@updateBar @ap, attributes.actions, attributes.maxActions
		@updateBar @tp, attributes.charge, 100

		turnPerc = Math.round(attributes.charge * 100) / 100
		@tp.find('.value').text "#{turnPerc}%"
		@el.removeClass()
		@el.addClass attributes.type
		return

	updateBar: (obj, value, maxValue) ->
		oWidth = obj.data 'oWidth'
		bar = obj.find '.bar'
		val = obj.find '.value'
		val.text "#{value}/#{maxValue}"
		width = value / maxValue * oWidth
		bar.width width

		return

class Ui.TurnList extends Wol.Views.View
	init: ->
		@el = $ '#turnList'
		@logs = @el.find '.logs'
		@template = ->
			$('#tpl-turnlist').html()
		return

	generate: (list) ->
		@logs.empty()
		list.forEach (item) =>
			log = $ @template()
			log.find('.unit').text item.name
			@logs.append log
		return


class Ui.Actions extends Wol.Views.View

	init: ->
		@el = $ '#actionMenu'
		@skip = @el.find '.skip'
		@move = @el.find '.move'
		@act = @el.find '.act'
		@cancel = @el.find '.cancel'

		@move.bind 'click', => @showMove()
		@skip.bind 'click', => @skipMove()
		@cancel.bind 'click', => @cancelAction()
		@act.bind 'click', => @showCommands()
		return

	show: (x,y) ->
		@el.removeClass()
		@el.addClass 'active'
		@el.css
			top: y
			left: x
		return

	hide: ->
		@el.removeClass 'active'
		return

	showMove: ->
		@trigger 'move'
		@showCancel()
		return

	skipMove: ->
		@trigger 'skip'
		return

	showCancel: ->
		@el.addClass 'cancel'

	cancelAction: ->
		@el.removeClass 'cancel'
		@trigger 'cancel'
		return

	showCommands: ->
		@trigger 'act'
		@showCancel()
		return


class Ui.Confirm extends Wol.Views.View

	init: ->
		@el				= $ "#actionConfirm"
		@confirmButton	= @el.find '.confirm'
		@cancelButton		= @el.find '.cancel'
		@cancelButton.bind 'click', => @cancel()
		@confirmButton.bind 'click', => @confirm()

	show: (x, y) ->
		@el.removeClass()
		@el.css top: y, left: x
		@el.addClass 'active'
		return

	hide: ->
		@el.removeClass 'active'
		return

	confirm: ->
		@trigger 'confirm'
		return

	cancel: ->
		@hide()
		@trigger 'cancel'
		return
		
