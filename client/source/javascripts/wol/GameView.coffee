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

@Wol

window.debug = true

# dump basic rendering events here
class Renderer extends Wol.Views.View
  init: ->
    document.body.onselectstart = -> false
    @canvas = document.getElementById('game')
      .getElementsByTagName('canvas')[0]
    @canvas.width = Wol.Settings.gameWidth
    @canvas.height = Wol.Settings.gameHeight
    @stage = new Stage @canvas
    @pause()
    Ticker.addListener tick: => @render()
    Ticker.setFPS 30
  
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
    @assetLoader = new Wol.AssetLoader
    Wol.getAsset = (name) => @assetLoader.get name
    @elReady()
    this

  buildUserInterface: ->
    # the layers of the rendering engine.
    # putting them into a namespace will make it easy to manage.
    @elements =
      background: new Bitmap Wol.getAsset 'background'
      terrain: new Bitmap Wol.getAsset 'terrain'
      hexContainer: new Wol.Views.HexContainer()
      hexLine: new Wol.Views.HexLineContainer()
      unitContainer: new Wol.Views.UnitContainer()
      viewport: new Container()

    @elements.viewport.addChild @elements.terrain
    @elements.viewport.addChild @elements.hexContainer.el
    @elements.viewport.addChild @elements.hexLine.el
    @elements.viewport.addChild @elements.unitContainer.el

    # Initiate the UI elements
    # putting them into a namespace will make it easy to remember
    @ui =
      console: new Wol.Ui.Console()
      unitMenu: new Wol.Ui.UnitMenu()
      cancelButton: new Wol.Ui.CancelButton()
      confirm: new Wol.Ui.Confirm()
      topVignette: new Wol.Ui.TopVignette()
    # add the elements to the stage
    # for `View` instances, they should have an `@el` property
    # which is a `Container` instance from EaselJS.
    @stage.addChild @elements.background
    @stage.addChild @elements.viewport
    this

  setConfigurations: ->
    # set the initial position of the terrain. (...)
    @elements.viewport.x = Wol.Settings.terrainX
    @elements.viewport.y = Wol.Settings.terrainY
    @elements.hexContainer.generate Wol.Settings.columns, Wol.Settings.rows
    this
  # =================================
  # !! DEBUG !!
  # =================================
  debug: ->
    this

# dump all the events here
class Wol.Views.GameView extends GameUi

  elReady: ->
    @assetLoader.download Wol.AssetList, @assetsReady
    return

  assetsReady: =>
    # once the assets are loaded, we can now build our user-interface
    @buildUserInterface().setConfigurations()
    @useRAF() if navigator.appVersion.indexOf('Chrome') > -1
    @startGame()
    @model.bind 'startGame', @startGame
    @model.bind 'addUser', @addUser
    @model.bind 'addUnit', @addUnit
    @model.bind 'moveUnit', @moveUnit
    @model.bind 'unitTurn', @unitTurn
    @model.connect()
    this
  
  startGame: =>
    @play()
    this

  addUser: (data) =>
    @ui.console.log data.message
    this

  addUnit: (data) =>
    @ui.console.log data.message
    {unitId, unitCode, tileX, tileY, face} = data
    unit = @elements.unitContainer.createUnitByCode unitCode
    unit.set data
    @elements.unitContainer.addUnit unit
    tile = Wol.Views.Hex::getCoordinates tileX, tileY
    unit.el.x = tile.x
    unit.el.y = tile.y
    this

  # GameUi.moveUnit
  moveUnit: (data) =>
    {unitId, points, message} = data
    @ui.console.log message
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

  # GameUi.unitTurn
  unitTurn: (data) =>
    {unitId, message} = data
    @ui.console.log message
    unit = @elements.unitContainer.getUnitById unitId
    # dont do anything if the unit isn't the active one
    return if @model.user.get('userId') isnt unit.get('userId')
    # add a hexagonal tile to the current tile the unit is positioned to
    unitTile = @elements.hexContainer.addTile (tileX: unit.get('tileX'), tileY: unit.get('tileY')), 'move'
    # these are for Ui placements only
    menuX = @elements.viewport.x + unitTile.x
    menuY = @elements.viewport.y + unitTile.y - unit.height
    @ui.unitMenu.show x: menuX, y: menuY
    # MOVE EVENT ----------------------------------
    @ui.unitMenu.bind 'move', =>
      $("#game").addClass "move"
      unit.get('tiles') or unit.set tiles: {}
      tiles = unit.get 'tiles'
      moveRadius = unit.getStat 'moveRadius'
      @elements.hexLine.start unitTile.x, unitTile.y
      @elements.hexContainer.removeTiles tiles.move if tiles.move?
      @elements.hexContainer.removeTiles tiles.generated if tiles.generate?
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
        return
        # end confirm.bind confirm
      # specify the occupied tiles for the tile to detect
      occupiedTiles = @elements.unitContainer.units.map (u) -> "#{u.get('tileX')}_#{u.get('tileY')}"
      # assign a click handler for the movable tiles.
      tiles.move.forEach (tile) =>
        tile.click =>
          console.log 'click tile', tile.id
          # cancel if already in this list
          return if tiles.selected.indexOf(tile) > -1
          # cancel if not an adjacent tile
          return if tiles.adjacent.indexOf(tile.id) is -1
          # cancel if insufficient actionpoints
          return if actionPoints - tile.cost < 0
          # cancel if there's an occupant in the tile
          return if occupiedTiles.indexOf(tile.id) > -1
          actionPoints -= tile.cost
          tiles.selected.push tile
          tiles.generated.push (=>
            t = @elements.hexContainer.addTile {tileX: tile.tileX, tileY: tile.tileY}, 'move'
            t.click =>
              return if tiles.generated.last() isnt t
              @ui.confirm.show
                x: @elements.viewport.x + tile.x
                y: @elements.viewport.y + tile.y
          )()
          tiles.adjacent = tile.getAdjacentPoints().map (p) -> "#{p.x}_#{p.y}" # assign the next set for cpu usage.
          @elements.hexLine.to tile.x, tile.y # draw the line
        return # tiles.move.forEach end
      return # end move event
    this # GameView.unitTurn
    # end unitTurn ---------------------------------------
