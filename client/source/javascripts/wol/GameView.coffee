#= require wol/AssetLoader
#= require wol/Ui
#= require wol/HexTile
#= require wol/Unit
#= require wol/HexContainer
#= require wol/UnitContainer
#= require wol/HexLineContainer
#= require wol/Commands


# ========================================
# NOTES
# ========================================
# - if you want to validate tile movement,
# - calculate the unit's total AP and compare
#
# Method Chaining
# - always make a `return this` statement for
#   every method.
#

Wol = @Wol

{AssetLoader, Views, Models, Collections, Ui, Settings} = Wol

window.debug = false

# dump basic rendering events here
class Renderer extends Views.View
  init: ->
    document.body.onselectstart = -> false
    @canvas = document.getElementById('game')
      .getElementsByTagName('canvas')[0]
    @canvas.width = Settings.gameWidth
    @canvas.height = Settings.gameHeight
    @stage = new Stage @canvas
    @pause()
    Touch.enable()
    Ticker.addListener tick: => @render()
    Ticker.setFPS 30
    #@useRAF()
  
  useRAF: ->
    Ticker.useRAF = true
    Ticker.setFPS 30
    this
  
  play: ->
    Ticker.setPaused false
    this
  
  pause: ->
    Ticker.setPaused true
    this

  render: ->
    @stage.update()
    this

# dump all basic UI related stuff here
class GameUi extends Renderer

  init: ->
    super()
    @buildUserInterface()
    @elReady()
    this

  buildUserInterface: ->
    # Initiate the UI elements
    # putting them into a namespace will make it easy to remember
    @ui =
      console: new Ui.Console()
      unitMenu: new Ui.UnitMenu()
      cancelButton: new Ui.CancelButton()
      confirm: new Ui.Confirm()
      topVignette: new Ui.TopVignette()
      curtain: new Ui.Curtain()
      commandList: new Ui.CommandList()
    this

  buildElements: ->
    # the layers of the rendering engine.
    # putting them into a namespace will make it easy to manage.
    @elements =
      background: new Bitmap Wol.getAsset 'background'
      terrain: new Bitmap Wol.getAsset 'terrain'
      hexContainer: new Views.HexContainer()
      hexLine: new Views.HexLineContainer()
      unitContainer: new Views.UnitContainer()
      damageCounter: new Views.DamageCounter()
      viewport: new Container()
    @elements.viewport.addChild @elements.terrain
    @elements.viewport.addChild @elements.hexContainer.background
    @elements.viewport.addChild @elements.hexContainer.el
    @elements.viewport.addChild @elements.hexLine.el
    @elements.viewport.addChild @elements.unitContainer.el
    @elements.viewport.addChild @elements.damageCounter.el
    # add the elements to the stage
    # for `View` instances, they should have an `@el` property
    # which is a `Container` instance from EaselJS.
    @stage.addChild @elements.background
    @stage.addChild @elements.viewport
    this

  setConfigurations: ->
    # set the initial position of the terrain. (...)
    @elements.viewport.x = Settings.terrainX
    @elements.viewport.y = Settings.terrainY
    @elements.hexContainer.generate Settings.columns, Settings.rows
    this

  isOccupiedTileById: (tileId) ->
    occupiedTiles = @elements.unitContainer.units.map (u) ->
      "#{u.get 'tileX'}_#{u.get 'tileY'}"
    occupiedTiles.indexOf(tileId) > -1

class Views.GameView extends GameUi

  elReady: ->
    @assetLoader = new AssetLoader
    Wol.getAsset = (name) => @assetLoader.get name
    @assetLoader.download Wol.AssetList, @assetsReady
    return

  assetsReady: =>
    # once the assets are loaded, we can now build our user-interface
    @buildElements().setConfigurations()
    if window.debug is true
      @debug()
      return
    @model.bind 'startGame', @startGame
    @model.bind 'addUser', @addUser
    @model.bind 'addUnit', @addUnit
    @model.bind 'moveUnit', @moveUnit
    @model.bind 'actUnit', @actUnit
    @model.bind 'unitTurn', @unitTurn
    @model.connect()
    this

  debug: ->

    unit = @addUnit
      message: 'debug add unit'
      unitId: String().randomId()
      userId: String().randomId()
      tileX: 3
      tileY: 3
      unitCode: 'lemurian_marine'
      unitName: 'Assault Marine'
      unitStat:
        baseHealth: 100
        baseEnergy: 10
        baseActions: 4
        health: 80
        energy: 9
        actions: 4
        moveRadius: 3
        charge: 0
        chargeSpeed: 10
      unitCommands: []

    unit_b = @addUnit
      message: 'debug add unit'
      unitId: String().randomId()
      userId: String().randomId()
      tileX: 4
      tileY: 3
      unitCode: 'lemurian_marine'
      unitName: 'Assault Marine'
      face: 'left'
      unitStat:
        baseHealth: 100
        baseEnergy: 10
        baseActions: 4
        health: 80
        energy: 9
        actions: 4
        moveRadius: 3
        charge: 0
        chargeSpeed: 10
      unitCommands: []

    after 1200, =>
      @actUnit
        commandCode: 'marine_pulse_rifle_shot'
        unitId: unit.get 'unitId'
        targets: [
          {
            unitId: unit_b.get 'unitId'
            damage: Math.random() * 40 + 40
          }
        ]
    this

  startGame: =>
    console.log 'start game'
    @play()
    @ui.curtain.hide()
    this

  addUser: (data) =>
    console.log 'addUser', data
    @ui.console.log data.message
    me = @model.user
    user = @model.getUserById data.userId
    user.set alternateColor: (=>
      Boolean @model.users.find (u)=>
        return false if u is me
        u.get('raceName') is user.get('raceName') and u.get('playerNumber') < user.get('playerNumber')
    )()
    this

  addUnit: (data) =>
    @ui.console.log data.message
    {userId, unitId, unitCode, unitName, tileX, tileY, face} = data
    {unitStats, unitCommands} = data
    user = @model.getUserById userId
    unit = @elements.unitContainer.createUnitByCode unitCode, user.get('alternateColor')
    unit.set
      tileX: tileX
      tileY: tileY
      unitCode: unitCode
      unitId: unitId
      unitName: unitName
      userId: userId
    unit.set unitStats
    unit.commands.add unitCommands
    unit.flip('left') if face is 'left'
    @elements.unitContainer.addUnit unit
    tile = Views.Hex::getCoordinates tileX, tileY
    unit.el.x = tile.x
    unit.el.y = tile.y
    unit

  # GameUi.moveUnit
  moveUnit: (data) =>
    {unitId, points, message} = data
    @ui.console.log message
    @elements.hexContainer.removeActiveTile()
    unit = @elements.unitContainer.getUnitById unitId
    units = @elements.unitContainer.units
    points = [{x: unit.get('tileX'), y: unit.get('tileY')}].concat points
    tiles = @elements.hexContainer.addTilesByPoints points, 'move'
    # unbind events first before you bind!
    unit.unbind()
    unit.bind 'moveUnitEnd', =>
      unit.unbind()
      @elements.hexLine.clear()
      @elements.hexContainer.removeTiles tiles
      @model.send 'moveUnitEnd',
        unitId: unitId
        type: 'move'
    # sort the unit list when a unit has moved to a new tile
    unit.bind 'move', =>
      units.forEach (u) ->
    unit.move tiles
    # create a hexagonal line
    @elements.hexLine.start tiles[0].x, tiles[0].y
    tiles.forEach (tile) => @elements.hexLine.to tile.x, tile.y
    this

  actUnit: (data) =>
    {unitId, commandCode, targets} = data
    @elements.hexContainer.removeActiveTile()
    tiles = @elements.hexContainer.get 'selection'
    tiles.selected = []
    unitActive = @elements.unitContainer.getUnitById unitId
    firstTarget = @elements.unitContainer.getUnitById targets[0].unitId
    @elements.hexContainer.set
      activeTile: @elements.hexContainer.addTile {tileX: unitActive.get('tileX'), tileY: unitActive.get('tileY')}, 'move'
    unitActive.flip (if unitActive.el.x > firstTarget.el.x then 'left' else' right')
    #events
    unitActive.unbind('attackEnd').bind 'attackEnd', =>
      unitActive.unbind 'attackEnd'
      unitActive.unbind 'attack'
      @elements.hexContainer.removeTiles tiles.selected if tiles.selected?
      targets.forEach (targetData) =>
        unit = @elements.unitContainer.getUnitById targetData.unitId
        return if !unit
        # tell the unit to die if there's no more health hehe
        if targetData.stats.health is 0
          unit.die()
        else
          unit.defendEnd()
        unit.set
          health: targetData.stats.health
          armor: targetData.stats.armor
          shield: targetData.stats.shield
      @model.send 'moveUnitEnd',
        unitId: unitId

    unitActive.unbind('attack').bind 'attack', (options) =>
      targets.forEach (targetData) =>

        unit = @elements.unitContainer.getUnitById targetData.unitId
        return if !unit
        unit.hit()
        damageData = targetData.damage
        damage =
          health: damageData.health
          shield: damageData.shield
          armor: damageData.armor
        if options?
          damage.health *= options.multiplier if options.multiplier?
        @elements.damageCounter.show
          x: unit.el.x
          y: unit.el.y - unit.height
          damage: damage.health

    targets.each (targetData) =>
      unit = @elements.unitContainer.getUnitById targetData.unitId
      return if !unit
      tiles.selected.push @elements.hexContainer.addTile {tileX: unit.get('tileX'), tileY: unit.get('tileY')}, 'target'
      unit.defend()

    unitActive.act
      code: commandCode

  # GameUi.unitTurn
  unitTurn: (data) =>
    {unitId, message} = data
    @ui.console.log message
    unit = @elements.unitContainer.getUnitById unitId
    # add a hexagonal tile to the current tile the unit is positioned to
    @elements.hexContainer.removeActiveTile()
    unitTile = @elements.hexContainer.addTile (tileX: unit.get('tileX'), tileY: unit.get('tileY')), 'move'
    @elements.hexContainer.setActiveTile unitTile
    # dont do anything if the unit isn't the active one
    return if @model.user.get('userId') isnt unit.get('userId')
    # these are for Ui placements only
    menuX = @elements.viewport.x + unitTile.x
    menuY = @elements.viewport.y + unitTile.y - unit.height
    @ui.unitMenu.show x: menuX, y: menuY
    # unit Menu Events
    @ui.unitMenu.unbind()

    # -----------------------------------------------------------------
    # ACTION: SKIP UNIT TURN
    # -----------------------------------------------------------------
    @ui.unitMenu.bind 'skip', =>
      @model.send 'skipTurn', unitId: unitId
      @elements.hexContainer.removeTile unitTile
      @ui.unitMenu.hide()
      @ui.unitMenu.unbind()
      return

    # -----------------------------------------------------------------
    # ACTION: MOVE UNIT
    # -----------------------------------------------------------------
    @ui.unitMenu.bind 'move', =>
      $("#game").addClass "move"
      unit.get('tiles') or unit.set tiles: {}
      moveRadius = unit.getStat 'moveRadius'
      @elements.hexLine.start unitTile.x, unitTile.y
      tiles = @elements.hexContainer.get 'selection'
      tiles.move = @elements.hexContainer.addTilesByPoints(
        unitTile.getAdjacentPoints(radius: moveRadius)
      )
      tiles.selected = []
      tiles.generated = [] # a tile graphic that is generated from a selected tile
      tiles.adjacent = unitTile.getAdjacentPoints().map (p) -> "#{p.x}_#{p.y}" # assign the next set for cpu usage.
      actionPoints = unit.getStat 'actions'
      # display states
      @ui.cancelButton.show()
      @ui.topVignette.show()
      @ui.unitMenu.hide()
      @ui.console.hide()
      # cancel button events
      @ui.cancelButton.unbind()
      @ui.cancelButton.bind 'cancel', =>
        $("#game").removeClass "move"
        @ui.cancelButton.hide()
        @ui.topVignette.hide()
        @ui.confirm.hide()
        @ui.unitMenu.show()
        @ui.console.show()
        @ui.cancelButton.unbind()
        @elements.hexLine.clear()
        @elements.hexContainer.removeTiles tiles.move if tiles.move?
        @elements.hexContainer.removeTiles tiles.generated if tiles.generated?
        return
      # confirm events
      @ui.confirm.unbind()
      @ui.confirm.bind 'cancel', =>
        @elements.hexLine.clear()
        @elements.hexContainer.removeTiles tiles.generated if tiles.generated?
        @ui.confirm.hide()
        # reset the Action Points
        tiles.selected = []
        tiles.generated = []
        tiles.adjacent = unitTile.getAdjacentPoints().map (p) -> "#{p.x}_#{p.y}" # assign the next set for cpu usage.
        actionPoints = unit.getStat 'actions'
        @elements.hexLine.start unitTile.x, unitTile.y
      # when the user confirms the tile movement selection
      @ui.confirm.bind 'confirm', =>
        $("#game").removeClass "move"
        @ui.cancelButton.hide()
        @ui.topVignette.hide()
        @ui.confirm.hide()
        @ui.unitMenu.hide()
        @ui.console.show()
        @elements.hexLine.clear()
        @elements.hexContainer.removeTiles tiles.move if tiles.move?
        @elements.hexContainer.removeTiles tiles.selected if tiles.selected?
        @elements.hexContainer.removeTiles tiles.generated if tiles.generated?
        @elements.hexContainer.removeTile unitTile
        @ui.confirm.unbind()
        @ui.cancelButton.unbind()
        @ui.unitMenu.unbind 'move'
        # when confirm is pressed/clicked, translate all the generated tiles
        # to an array of objects with tileX and tileY as their properties.
        @model.send 'moveUnit',
          unitId: unitId
          points: tiles.generated.map (tile) -> tileX: tile.tileX, tileY: tile.tileY
          face: (if unit.el.scaleX is 1 then 'right' else 'right')
        return
        # end confirm.bind confirm
      # assign a click handler for the movable tiles.
      tiles.move.forEach (tile) =>
        tile.click =>
          # cancel if already in this list
          return if tiles.selected.indexOf(tile) > -1
          # cancel if not an adjacent tile
          return if tiles.adjacent.indexOf(tile.id) is -1
          # cancel if insufficient actionpoints
          return if actionPoints - tile.cost < 0
          # cancel if there's an occupant in the tile
          return if @isOccupiedTileById(tile.id)
          actionPoints -= tile.cost
          tiles.selected.push tile
          tiles.generated.push ( =>
            t = @elements.hexContainer.addTile {tileX: tile.tileX, tileY: tile.tileY}, 'move'
            t.click =>
              return if tiles.generated.last() isnt t
              @ui.confirm.show
                x: @elements.viewport.x + tile.x
                y: @elements.viewport.y + tile.y
            t
          )()
          tiles.adjacent = tile.getAdjacentPoints().map (p) -> "#{p.x}_#{p.y}" # assign the next set for cpu usage.
          @elements.hexLine.to tile.x, tile.y # draw the line
        return # tiles.move.forEach end
      return # end move event

    # -----------------------------------------------------------------
    # ACTION: ACT UNIT
    # -----------------------------------------------------------------
    @ui.unitMenu.bind 'act', =>
      commands = unit.commands.collections.map (item) -> item.attributes
      tiles = @elements.hexContainer.get 'selection'
      # initialize
      @ui.commandList.show x: menuX, y: menuY
      @ui.unitMenu.hide()
      # when show the commands and assign event handlers to them
      @ui.commandList.generate(commands)
      @ui.commandList.unbind('cancel').bind 'cancel', =>
        @ui.commandList.unbind()
        @ui.cancelButton.unbind()
        @ui.cancelButton.hide()
        @ui.commandList.hide()
        @ui.unitMenu.show()
      # bind events from the command list
      @ui.commandList.unbind('command').bind 'command', (commandData) =>
        @ui.topVignette.show()
        @ui.cancelButton.show()
        @ui.commandList.hide()
        @ui.console.hide()
        # show the radius of the tiles
        tiles.move = @elements.hexContainer.addTilesByPoints(
          unitTile.getAdjacentPoints(radius: commandData.radius)
          , 'act')
        tiles.selected = []
        tiles.generated = []
        # assign click events for tiles that have units in them.
        tiles.move.forEach (tile) =>
          # remove any existing tiles
          occupyingUnit = @elements.unitContainer.getUnitByTileId tile.id
          # skip tiles that do not have units on top of them.
          return if occupyingUnit is undefined
          # assign click/touch events that would display the container
          tile.click =>
            # cancel if already in the list
            return if tiles.selected.indexOf(tile) > -1
            tiles.selected.push tile

            @elements.hexContainer.removeTiles tiles.move if tiles.move?
            # generated tiles are the tiles whose tileId gets sent to the server
            # we only send the currently selected tile.
            # will probably use multiple tiles in the future.
            tiles.generated = []
            tiles.generated.push ( =>
              generated = @elements.hexContainer.addTile
                x: tile.tileX
                y: tile.tileY
              , 'target'
              generated
            )()
            points = tiles.generated.map (t) ->
              tileX: t.tileX
              tileY: t.tileY
            @ui.confirm.show
              x: @elements.viewport.x + tile.x
              y: @elements.viewport.y + tile.y
            # confirm events > cancel
            @ui.confirm.unbind('cancel').bind 'cancel', =>
              @ui.confirm.unbind()
              @ui.confirm.hide()
              @ui.console.show()
              @ui.cancelButton.hide()
              @ui.topVignette.hide()
              @ui.unitMenu.show()
              @elements.hexContainer.removeTiles tiles.generated if tiles.generated?
              @elements.hexContainer.removeTiles tiles.move if tiles.move?
            # confirm events > confirm
            @ui.confirm.unbind('confirm').bind 'confirm', =>
              @ui.confirm.unbind()
              @ui.confirm.hide()
              @ui.console.show()
              @ui.cancelButton.hide()
              @ui.topVignette.hide()
              @elements.hexContainer.removeTiles tiles.generated if tiles.generated?
              @elements.hexContainer.removeTiles tiles.move if tiles.move?
              @model.send 'actUnit',
                unitId: unitId
                commandCode: commandData.code
                points: points
              @elements.hexContainer.removeTile unitTile
              delete tiles.selected
              delete tiles.move
              delete tiles.generated

        # initiate the cancel button
        @ui.cancelButton.unbind('cancel').bind 'cancel', =>
          @elements.hexContainer.removeTiles tiles.move if tiles.move?
          @ui.topVignette.hide()
          @ui.cancelButton.hide()
          @ui.commandList.hide()
          @ui.unitMenu.show()
