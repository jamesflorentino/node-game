Ui = Wol.Ui

class Modal extends Wol.Views.View

	show: (position) ->
		if position?
			if position.x? and position.y?
				@el.css top: position.y, left: position.x
		@el.removeClass 'hidden'
		@el.addClass 'active'

	hide: ->
		@el.addClass 'hidden'
		@el.removeClass 'active'


class Ui.Console extends Modal

	tpl: (data) ->
		"""
		<li>#{data.message}</li>
		"""
	init: ->
		@el = $ "#console"
		@logs = @el.find 'ul'
		@logs.empty()
	
	log: (message) -> @logs.append @tpl message: message

class Ui.UnitMenu extends Modal

	init: ->
		@el = $ "#unit-menu"
		@moveButton = @el.find '.move'
		@actButton = @el.find '.act'
		@skipButton = @el.find '.skip'
		@moveButton.click => @trigger 'move'
		@actButton.click => @trigger 'act'
		@skipButton.click => @trigger 'skip'

	
class Ui.CancelButton extends Modal

	init: ->
		@el = $ "#cancel-button"
		@el.click => @trigger 'cancel'

class Ui.TopVignette extends Modal

	init: ->
		@el = $ "#top-vignette"

