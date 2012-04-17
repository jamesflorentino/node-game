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
#window.debug = true

# dump basic rendering events here
class Renderer extends Views.View
  init: ->
    document.body.onselectstart = -> false
    @canvas = document.getElementById('game')
      .getElementsByTagName('canvas')[0]
    @canvas.width = Settings.gameWidth
    @canvas.height = Settings.gameHeight
    @stage = new Stage @canvas
    Touch.enable()
    Ticker.addListener tick: => @render()
    Ticker.setFPS 30
    @pause()
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
      disconnected: new Ui.Disconnected()
      unitInfo: new Ui.UnitInfo()
      endGame: new Ui.EndGame()
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
      gaugeContainer: new Views.GaugeContainer()
      damageCounter: new Views.DamageCounter()
      actionPoints: new Views.ActionPoints()
      viewport: new Container()

    #@elements.viewport.addChild @elements.terrain
    @elements.viewport.addChild @elements.hexContainer.background
    @elements.viewport.addChild @elements.hexContainer.el
    @elements.viewport.addChild @elements.hexLine.el
    @elements.viewport.addChild @elements.unitContainer.el
    @elements.viewport.addChild @elements.gaugeContainer.el
    @elements.viewport.addChild @elements.damageCounter.el
    @elements.viewport.addChild @elements.actionPoints.el

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
    unit = @elements.unitContainer.getUnitByTileId tileId
    if unit?
      if unit.dead is true
        return false
      return true
    false

class Views.GameView extends GameUi

  elReady: ->
    @assetLoader = new AssetLoader
    Wol.getAsset = (name) => @assetLoader.get name
    @assetLoader.download Wol.AssetList, @assetsReady
    return

  assetsReady: =>
    # once the assets are loaded, we can now build our user-interface
    @buildElements().setConfigurations()
    @model.bind 'disconnect', @disconnect
    @model.bind 'startGame', @startGame
    @model.bind 'endGame', @endGame
    @model.bind 'addUser', @addUser
    @model.bind 'addUnit', @addUnit
    @model.bind 'removeUnit', @removeUnit
    @model.bind 'moveUnit', @moveUnit
    @model.bind 'actUnit', @actUnit
    @model.bind 'unitTurn', @unitTurn
    return @debug() if window.debug is true
    @model.connect()
    this

  debugPathFinding: ->
    {getAdjacentHexes, getHeuristics} = HexUtil
    start = x: 2, y: 2
    @elements.hexContainer.addTile start
    @elements.hexContainer.bind 'hex', (tileId) =>
      destination = @elements.hexContainer.toPoint tileId
      openList = [start]
      complete = false
      while complete is false
        lowestCost = 100 # initial arbitrary value
        # consider the best node in the open list (the node with the lowest f value)
        current = openList.last()
        adjacent = getAdjacentHexes current.x, current.y
        adjacent.sort (a, b) ->
          getHeuristics(a, destination) > getHeuristics(b, destination)
        point = adjacent.first()
        openList.push point
        # this node is the goal, then we are done
        if point.x is destination.x and point.y is destination.y
          complete = true
          break
      @elements.hexContainer.addTilesByPoints openList, 'target'
      @stage.update()
    @stage.update()
 

  # /////////////////////////////
  debug: ->
    tempUser =
      userId: '1234567890'
      userName: 'James'
      playerNumber: 0
      playerType: 'player'
      raceName: 'lemurian'
      message: 'yo!'
    tempUserB =
      userId: '9229292'
      userName: 'lols'
      playerNumber: 1
      playerType: 'player'
      raceName: 'lemurian'
      message: 'asdfasdf'

    @model.user.set tempUser
    @model.addUser tempUser
    @model.addUser tempUserB

    user = @model.users.at 0
    userB = @model.users.at 1

    unit = @addUnit
      message: 'debug add unit'
      unitId: String().randomId()
      userId: user.get('userId')
      tileX: 0
      tileY: 2
      unitCode: 'lemurian_marine'
      unitName: 'Assault Marine'
      unitStats:
        baseHealth: 100
        baseArmor: 100
        baseShield: 0
        baseEnergy: 10
        baseActions: 6
        health: 80
        armor: 10
        shield: 5
        energy: 9
        actions: 6
        moveRadius: 3
        charge: 0
        chargeSpeed: 10
      unitCommands: []

    unit_b = @addUnit
      message: 'debug add unit'
      unitId: String().randomId()
      userId: user.get('userId')
      tileX: 0
      tileY: 1
      unitCode: 'lemurian_marine'
      unitName: 'Assault Marine'
      face: 'left'
      unitStats:
        baseHealth: 100
        baseEnergy: 10
        baseShield: 5
        baseArmor: 0
        baseActions: 6
        health: 80
        armor: 3
        shield: 3
        energy: 9
        actions: 4
        moveRadius: 3
        charge: 0
        chargeSpeed: 10
      unitCommands: []

    @ui.curtain.hide()
    @startGame()
    after 1000, =>
      # rrr
      mode = 'move'
      mode = 'act'
      mode = 'turn'
      switch mode
        when 'turn'
          @unitTurn
            unitId: unit.get 'unitId'
            message: 'asdf'
            stats: unit.get 'unitStats'
        when 'move'
          @moveUnit
            unitId: unit.get 'unitId'
            points: [{tileX: 4, tileY: 3}, {tileX: 4, tileY: 4}, {tileX: 4, tileY: 5}]
            message: 'moving'
        when 'act'
          @actUnit
            unitId: unit.get 'unitId'
            message: 'attack'
            commandCode: 'marine_pulse_rifle_shot'
            targets: [
              unitId: unit_b.get 'unitId'
              damage:
                armor: 0
                shield: 0
                health: 25
              stats:
                armor: 0
                shield: 0
                health: 25
            ]
      return
    #after 5000, => @pause()
    this

  # /////////////////////////////
  disconnect: =>
    @ui.disconnected.show()
    @model.disconnect()
    @pause()
    this

  startGame: =>
    @play()
    @ui.curtain.hide()
    @elements.hexContainer.bind 'hex', @showUnitInfoByTileId
    this

  showUnitInfoByTileId: (tileId) =>
    unit = @elements.unitContainer.getUnitByTileId tileId
    if unit is undefined
      @ui.unitInfo.hide()
      return
    @ui.unitInfo.data unit
    @ui.unitInfo.show()
    #@elements.viewport.x = Wol.Settings.gameWidth * 0.5 - unit.el.x
    return

  endGame: (data) =>
    {userId, message} = data
    console.log 'endgame', data
    @model.unbind 'disconnect'
    if userId?
      @ui.endGame.show()
      after 1000, => @pause()
      return
    @ui.disconnected.message message
    @ui.disconnected.show()
    this

  addUser: (data) =>
    @ui.console.log data.message
    me = @model.user
    user = @model.getUserById data.userId
    user.set alternateColor: (=>
      Boolean @model.users.find (u)=>
        return false if u is me
        u.get('raceName') is user.get('raceName') and u.get('playerNumber') < user.get('playerNumber')
    )()
    this

  # ///////////////////////////////////////////////
  # GameUi.addUnit
  addUnit: (data) =>
    @ui.console.log data.message
    {userId, unitId, unitCode, unitName, tileX, tileY, face} = data
    {unitStats, unitCommands} = data
    # disregard if the user doesn't exist
    user = @model.getUserById userId
    return if !user
    # check if the user needs an alternate color
    # set all the server data into the unit
    # set the commands, todo: should just use a normal object for them vs classes.
    # set the direction of the unit
    # spawn the unit. this will trigger some events
    alternateColor = user.get 'alternateColor'
    unit = @elements.unitContainer.createUnitByCode unitCode, alternateColor
    unit.set data
    unit.commands.add unitCommands
    unit.flip('left') if face is 'left'
    unit.spawn()
    # generate the health, armor, shield gauges
    gauge = @elements.gaugeContainer.add unitId
    gauge.updateElements unitStats
    gauge.update unitStats
    gauge.el.regX = unit.el.regX
    gauge.el.regY = unit.el.regY + 20
    # get the coordinates of the tile that the unit is positioned in.
    tile = Views.Hex::getCoordinates tileX, tileY
    unit.position tile.x, tile.y
    gauge.position tile.x, tile.y
    # finally add the thing intot he display list
    @elements.unitContainer.addUnit unit

  # ///////////////////////////////////////////////
  removeUnit: (data) =>
    {unitId} = data
    unit = @elements.unitContainer.getUnitById unitId
    return if !unit
    unit.remove()

  # ///////////////////////////////////////////////
  # GameUi.moveUnit
  # data arguments
  # unitId: <String>
  # points: <Array>
  # message: <String>
  moveUnit: (data) =>
    {unitId, points, message} = data
    @ui.console.log message
    # remove any active tile remaining
    @elements.hexContainer.removeActiveTile()
    # define the unit, units, and points
    unit = @elements.unitContainer.getUnitById unitId
    units = @elements.unitContainer.units
    points = [{x: unit.get('tileX'), y: unit.get('tileY')}].concat points
    tiles = @elements.hexContainer.addTilesByPoints points, 'move'
    gauge = @elements.gaugeContainer.getById unitId
    # ----------------
    # when the unit has stopped moving
    unit.unbind('moveUnitEnd').bind 'moveUnitEnd', =>
      unit.unbind 'moveUnitEnd'
      unit.unbind 'move'
      @elements.gaugeContainer.show()
      @elements.hexLine.clear()
      @elements.hexContainer.removeTiles tiles
      @model.send 'moveUnitEnd',
        unitId: unitId
        type: 'move'
      return
    # trigger an event whenever the unit is about to move.
    # TO-DO sort the unit list when a unit has moved to a new tile
    unit.unbind('move').bind 'move', (moveData) =>
      gauge.move moveData
      return
    # displace the unit
    # hide the gauges
    unit.move tiles
    @elements.gaugeContainer.hide()
    # create a hexagonal line
    @elements.hexLine.start tiles[0].x, tiles[0].y
    tiles.each (tile) => @elements.hexLine.to tile.x, tile.y
    this

  # ///////////////////////////////////////////////
  actUnit: (data) =>
    {unitId, commandCode, targets} = data
    @elements.hexContainer.removeActiveTile()
    tiles = @elements.hexContainer.get 'selection'
    tiles.selected = []
    # get the first target of the targets list to be able
    # to determine which side the unit will face to.
    unitActive = @elements.unitContainer.getUnitById unitId
    firstTarget = @elements.unitContainer.getUnitById targets[0].unitId
    unitActive.flip (if unitActive.el.x > firstTarget.el.x then 'left' else' right')
    # assign the activeTile as a property so we can easily remove this
    # asynchronusly from other events
    @elements.hexContainer.set
      activeTile: (=>
        @elements.hexContainer.addTile
          tileX: unitActive.get 'tileX'
          tileY: unitActive.get 'tileY'
        , 'move'
      )()
    tileId = @elements.hexContainer.get('activeTile').id
    @showUnitInfoByTileId tileId
    # when the active unit finishes attacking
    unitActive.unbind('attackEnd').bind 'attackEnd', =>
      unitActive.unbind()
      @elements.hexContainer.removeTiles tiles.selected if tiles.selected?
      targets.each (targetData) =>
        {stats} = targetData
        unit = @elements.unitContainer.getUnitById targetData.unitId
        gauge = @elements.gaugeContainer.getById targetData.unitId
        return if !unit
        # tell the unit to die if there's no more health hehe
        if stats.health is 0
          unit.die()
          gauge.hide()
        else
          unit.defendEnd()
        # set the final properties
        unit.setStat
          health: stats.health
          armor: stats.armor
          shield: stats.shield
      @model.send 'moveUnitEnd',
        unitId: unitId
    # whenever a unit dispatches an attack event
    # which is assigned on animation events.
    unitActive.unbind('attack').bind 'attack', (options) =>
      # the unit can optionally dispatcha a multiplier for dividing damage between
      # animations.
      # iterate all the units and perform operation
      targets.each (targetData) =>
        unit = @elements.unitContainer.getUnitById targetData.unitId
        gauge = @elements.gaugeContainer.getById unit.get 'unitId'
        return if unit is undefined
        {damage, stats} = targetData
        damageData =
          health: damage.health
          shield: damage.shield
          armor: damage.armor
        # do some fancy pancy here if the unit dispatches some
        # sort of animation event.
        if options?
          if options.multiplier?
            damageData.health *= options.multiplier
        # show the damage animation
        @elements.damageCounter.show
          x: unit.el.x
          y: unit.el.y - unit.height
          damage: damageData.health
        # dispatch a hit unit for animation
        # also set the new health
        unit.hit()
        unit.setStat
          health: unit.getStat('health') - damageData.health
        # set the health gauge
        gauge.update
          baseHealth: stats.baseHealth or unit.getStat('baseHealth')
          health: unit.getStat('health')
    # add an attack tile indicator below all affected units
    # tell the units to perform a defend animation
    targets.each (targetData) =>
      unit = @elements.unitContainer.getUnitById targetData.unitId
      return if !unit
      tiles.selected.push @elements.hexContainer.addTile {tileX: unit.get('tileX'), tileY: unit.get('tileY')}, 'target'
      unit.defend()

    unitActive.act
      code: commandCode

  # ///////////////////////////////////////////////
  # GameUi.unitTurn
  unitTurn: (data) =>
    {unitId, message, stats} = data
    {hexContainer, unitContainer, hexLine} = @elements
    unit = unitContainer.getUnitById unitId
    # add a hexagonal tile to the current tile the unit is positioned to
    return if unit is undefined
    @model.set activeUnit: unit
    unitTile = hexContainer.addTile
      tileX: unit.get('tileX')
      tileY: unit.get('tileY')
      , 'move'
    hexContainer.setActiveTile unitTile
    # dont do anything if the unit isn't the active one
    return if @model.user.get('userId') isnt unit.get('userId')
    tileId = "#{unit.get 'tileX'}_#{unit.get 'tileY'}"
    @showUnitInfoByTileId tileId
    menuX = @elements.viewport.x + unitTile.x
    menuY = @elements.viewport.y + unitTile.y - unit.height
    @ui.unitMenu.show()
    @ui.unitMenu.unbind()
    unit.setStat actions: stats.actions
    @ui.unitMenu.unbind('skip').bind 'skip', @onSkip

    # ////////////////////////////////////////////////////////////////
    # skip turn
    # ---------------------------------------------------------------
    @ui.unitMenu.bind 'skip', @turnSkip
      

    # ////////////////////////////////////////////////////////////////
    # move unit
    # ---------------------------------------------------------------
    @ui.unitMenu.unbind('move').bind 'move', @turnMove
      


    # /////////////////////////////////////////////////////////////////
    # unitTurn -> act
    @ui.unitMenu.bind 'act', =>
      commands = unit.commands.collections.map (item) -> item.attributes
      tiles = @elements.hexContainer.get 'selection'
      actionPoints = unit.getStat 'actions'
      # initialize
      @ui.commandList.show x: menuX, y: menuY
      @ui.unitMenu.hide()
      # when show the commands and assign event handlers to them
      @ui.commandList.generate(commands, actions: actionPoints)
      @ui.commandList.unbind('cancel').bind 'cancel', =>
        @ui.commandList.unbind()
        @ui.cancelButton.unbind()
        @ui.cancelButton.hide()
        @ui.commandList.hide()
        @ui.unitMenu.show()
      # bind events from the command list
      @ui.commandList.unbind('command').bind 'command', (commandData) =>
        {cost} = commandData
        @ui.topVignette.show()
        @ui.cancelButton.show()
        @ui.commandList.hide()
        @ui.console.hide()
        # show the action point gauge
        @elements.actionPoints.setValues actionPoints, unit.getStat 'baseActions'
        @elements.actionPoints.position unit.el.x, unit.el.y - unit.height
        # show the radius of the tiles
        tiles.move = @elements.hexContainer.addTilesByPoints(
          unitTile.getAdjacentPoints(radius: commandData.radius)
          , 'act')
        tiles.selected = []
        tiles.generated = []
        # assign click events for tiles that have units in them.
        tiles.move.each (tile) =>
          # remove any existing tiles
          occupyingUnit = @elements.unitContainer.getUnitByTileId tile.id
          # skip tiles that do not have units on top of them.
          return if occupyingUnit is undefined
          # skip if the unit is dead :P
          return if occupyingUnit.dead is true
          # assign click/touch events that would display the container
          tile.click =>
            # cancel if already in the list
            return if tiles.selected.indexOf(tile) > -1
            tiles.selected.push tile
            # cancel if insufficient points
            actionPoints = unit.getStat 'actions'
            return if actionPoints - cost < 0
            # show the action point gauge
            @elements.actionPoints.deduct cost
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
              @elements.actionPoints.setValues actionPoints, unit.getStat 'baseValue'
            # confirm events > confirm
            @ui.confirm.unbind('confirm').bind 'confirm', =>
              @ui.confirm.unbind()
              @ui.confirm.hide()
              @ui.console.show()
              @ui.cancelButton.hide()
              @ui.topVignette.hide()
              @elements.hexContainer.removeTiles tiles.generated if tiles.generated?
              @elements.hexContainer.removeTiles tiles.move if tiles.move?
              @elements.actionPoints.hide()
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
          @elements.actionPoints.hide()
          @elements.hexContainer.removeTiles tiles.move if tiles.move?
          @ui.topVignette.hide()
          @ui.cancelButton.hide()
          @ui.commandList.hide()
          @ui.unitMenu.show()

  turnSkip: =>
    unit = @model.get 'activeUnit'
    unitId = unit.get 'unitId'
    @elements.hexContainer.removeActiveTile()
    @ui.unitMenu.hide()
    @ui.unitMenu.unbind()
    @model.send 'skipTurn', unitId: unitId

  turnMove: =>
    unit = @model.get 'activeUnit'
    unitTile = @elements.hexContainer.get 'activeTile'
    tileId = unitTile.id
    unitId = unit.get 'unitId'
    @ui.unitMenu.hide()
    @elements.actionPoints.setValues unit.getStat('actions'), unit.getStat('baseActions')
    @elements.actionPoints.position unit.el.x, unit.el.y - unit.height
    tiles = @elements.hexContainer.get 'selection'
    moveRadius = unit.getStat 'moveRadius'
    # generate the moveable tiles
    adjacentTiles = HexUtil.getAdjacentHexes unitTile.tileX, unitTile.tileY, moveRadius
    tiles.move = @elements.hexContainer.addTilesByPoints adjacentTiles
    # assign the starting point for pathfinding
    startPoint = @elements.hexContainer.toPoint tileId
    # assign click handlers
    tiles.move.each (tile) =>
      tile.click =>
        @elements.actionPoints.setValues unit.getStat('actions'), unit.getStat('baseActions')
        @elements.hexContainer.removeTiles tiles.selected if tiles.selected?
        destination = @elements.hexContainer.toPoint tile.id
        return if @isOccupiedTileById "#{destination.x}_#{destination.y}"
        openList = [startPoint]
        actions = unit.getStat 'actions'
        # add one just for the first tile in the open list
        actions += 1
        # path-finding algorithm start
        complete = false
        while complete is false
          current = openList.last()
          adjacent = HexUtil.getAdjacentHexes current.x, current.y
          adjacent = HexUtil.setBounds adjacent, Settings.columns, Settings.rows
          adjacent.sort (a,b) ->
            HexUtil.getHeuristics(a, destination) > HexUtil.getHeuristics(b, destination)
          # check if the target is occupied, until it gets to the next available tile.
          nextPoint = undefined
          i = 0
          while i < adjacent.length
            point = adjacent[i]
            if @isOccupiedTileById("#{point.x}_#{point.y}") is false
              nextPoint = point
              actions -= 1
              @elements.actionPoints.deduct 1
              break
            i++
          # check for action points left
          # if there's no passable tile, then let's just cancel
          break if actions <= 0 or nextPoint is undefined
          openList.push nextPoint
          # if this node is the goal, break the loop and then we're done
          break if nextPoint.x is destination.x and point.y is destination.y
        # remove the first element
        tiles.selected = @elements.hexContainer.addTilesByPoints openList, 'move'
        tiles.selected.last().click =>
          tiles.selected.last().removeClick()
          @ui.confirm.unbind('confirm').bind 'confirm', =>
            @hideHUD()
            @unbindHUDEvents()
            points = @elements.hexContainer.convertToPoints tiles.selected
            points.splice 0,1
            @model.send 'moveUnit',
              unitId: unitId
              points: points
              face: (if unit.el.scaleX > 0 then 'right' else 'left')
            @elements.hexContainer.removeSelectionTiles()
            @elements.hexContainer.removeTile unitTile
          @ui.confirm.unbind('cancel').bind 'cancel', =>
            unit.move unitTile
            @ui.confirm.hide()
            @elements.hexContainer.removeTiles tiles.selected
            @elements.actionPoints.setValues unit.getStat('actions'), unit.getStat('baseActions')
          @ui.confirm.show
            x: @elements.viewport.x + tiles.selected.last().x
            y: @elements.viewport.y + tiles.selected.last().y - unit.height
          @elements.gaugeContainer.hide()
          @elements.actionPoints.hide()

    @ui.cancelButton.show()
    @ui.cancelButton.unbind().bind 'cancel', =>
      @elements.actionPoints.hide()
      @elements.hexContainer.removeSelectionTiles()
      @ui.cancelButton.hide().unbind()
      @ui.unitMenu.show()

  #///////////////////////////////////////////
  hideHUD: ->
    @ui.cancelButton.hide()
    @ui.topVignette.hide()
    @ui.confirm.hide()
    @ui.unitMenu.hide()
    @ui.console.show()
    @elements.actionPoints.hide()
    this

  #///////////////////////////////////////////
  unbindHUDEvents: ->
    @ui.confirm.unbind()
    @ui.cancelButton.unbind()
    @ui.unitMenu.unbind()
    this
