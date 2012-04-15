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
    @hide()
  
  log: (message) -> @logs.append @tpl message: message
  show: -> this
  hide: -> @el.hide()

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

class Ui.Confirm extends Modal

  init: ->
    @el = $ "#confirm-action"
    @confirmButton = @el.find ".confirm"
    @cancelButton = @el.find ".cancel"
    @confirmButton.click => @trigger 'confirm'
    @cancelButton.click => @trigger 'cancel'

class Ui.Curtain extends Modal
  init: ->
    @el = $ "#curtain"

  hide: ->
    super()

class Ui.CommandList extends Modal
  init: ->
    @el = $ "#command-list"
    @list = @el.find 'ul'
    @cancelButton = @el.find '.cancel'
    @tpl = (data) ->
      """
      <li>
        <span>#{data.name}</span>
        <div class="cost">#{data.cost}</div>
      </li>
      """
    @cancelButton.click => @trigger 'cancel'

  generate: (list, options) ->
    {actions} = options
    @list.empty()
    list.forEach (item, i) =>
      li = $ @tpl
        name: item.name
        cost: item.cost
      if actions - item.cost >= 0
        li.click => @trigger 'command', item
      else
        li.addClass 'insufficient'
      @list.append li
    this

class Ui.Disconnected extends Modal
  init: ->
    @el = $ "#disconnected"
    @title = @el.find 'h2'
    @el.find('.confirm').click ->
      window.location.reload true
      return

  message: (message) ->
    console.log 'disconnected', message
    @title.text message

# /////////////////////////////
class Ui.UnitInfo extends Modal
  init: ->
    @el = $ "#unit-info-you"
    @avatar = @el.find '.avatar'
    @unitName = @el.find '.unit_name'
    @roles = @el.find '.roles'
    @gaugeHP = @el.find '.health.gauge'
    @gaugeEP = @el.find '.energy.gauge'
    @barWidthHealth = @gaugeHP.find('.bar .value').width()
    @barWidthEnergy = @gaugeEP.find('.bar .value').width()

  data: (unit) ->
    health = unit.getStat 'health'
    energy = unit.getStat 'energy'
    baseHealth = unit.getStat 'baseHealth'
    baseEnergy = unit.getStat 'baseEnergy'
    console.log 'unitRole', unit.get 'unitRole'
    @avatar.addClass unit.get 'unitCode'
    @unitName.text unit.get 'unitName'
    @roles.text unit.get 'unitRole'
    @gaugeHP.find('.bar .value').width @barWidthHealth * (health / baseHealth)
    @gaugeEP.find('.bar .value').width @barWidthEnergy * (energy / baseEnergy)
    @gaugeHP.find('.values .value').text health
    @gaugeHP.find('.values .total').text "/#{baseHealth}"
    @gaugeEP.find('.values .value').text energy
    @gaugeEP.find('.values .total').text "/#{baseEnergy}"

  ###
  show: ->
    @el.removeClass 'active'
    after 0, =>
      @el.removeClass 'hidden'
      @el.addClass 'active'
  ###


class Ui.EndGame extends Modal
  init: ->
    @el = $ "#endgame"
