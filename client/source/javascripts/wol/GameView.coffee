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
#		every method.
#

@Wol

window.debug = true

# dump basic rendering events here
class Renderer extends Wol.Views.View
	init: ->
		@canvas = document.getElementById('game').getElementsByTagName('canvas')[0]
		@canvas.width = Wol.Settings.gameWidth
		@canvas.height = Wol.Settings.gameHeight
		@stage = new Stage @canvas
		@pause()
		Ticker.addListener tick: => @render()
	
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
		@useRAF()
			.startGame()
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
		{unitId} = data
		{unitCode} = data
		unit = @elements.unitContainer.createUnitByCode unitCode
		unit.set data
		@elements.unitContainer.addUnit unit
		this
	
	moveUnit: (data) =>
		@ui.console.log data.message
		unitId = data.unitId
		unit = @elements.unitContainer.getUnitById unitId
		#tiles = @elements.hexContainer.getTilesByPoints data.points
		tiles = @elements.hexContainer.addTilesByPoints data.points, 'move'
		unit.bind 'moveUnitEnd', =>
			@elements.hexLine.clear()
			@elements.hexContainer.removeTiles tiles
			@model.send 'moveUnitEnd',
				unitId: unitId
		unit.move tiles
		@elements.hexLine.start tiles[0].x, tiles[0].y
		tiles.forEach (tile) =>
			@elements.hexLine.to tile.x, tile.y
		this

	unitTurn: (data) =>
		@ui.console.log data.message
		{unitId} = data
		{message} = data
		unit = @elements.unitContainer.getUnitById unitId
		point =
			tileX		: unit.get 'tileX'
			tileY : unit.get 'tileY'
		unitTile = @elements.hexContainer.addTile point, 'move'
		menuX = @elements.viewport.x + unitTile.x
		menuY = @elements.viewport.y + unitTile.y - unit.height

		tiles =
			# the movable tiles by radius
			move: undefined
			# the selected tiles
			selected: undefined
			# the adjacent tiles the user can currently select
			generated: undefined

		@ui.unitMenu.show x: menuX, y: menuY
		@ui.cancelButton.bind 'cancel', =>
			@ui.cancelButton.hide()
			@ui.topVignette.hide()
			@ui.unitMenu.show()
			@ui.console.show()
			@elements.hexLine.clear()
			@elements.hexContainer.removeTiles tiles.move if tiles.move?

		# logic for the move action
		# you should move this to a separate function
		@ui.unitMenu.bind 'move', =>
			@ui.cancelButton.show()
			@ui.topVignette.show()
			@ui.unitMenu.hide()
			@ui.console.hide()
			@elements.hexContainer.removeTiles tiles.radius if tiles.radius?
			moveRadius = unit.getStat 'moveRadius'
			# generate the radius of the movable area.
			tiles.move = @elements.hexContainer.addTilesByPoints(
				unitTile.getAdjacentPoints(radius: moveRadius)
			)
			# create a new selection array, and
			tiles.selected = []
			tiles.generated = []
			# assign a click handler for the movable tiles.
			@elements.hexLine.start unitTile.x, unitTile.y
			tiles.move.forEach (tile) =>
				tile.click =>
					# dont add if it already exists in the array.
					return if tiles.selected.indexOf(tile) > -1
					if tiles.selected.last() is tile
						return
					lastTile = tiles.selected.last() or unitTile
					# this checks if the clicked tile is a valid
					# adjacent neighboring tile.
					adjacentPoints = lastTile.getAdjacentPoints().filter (point) ->
						tile.tileX is point.x and tile.tileY is point.y
					# if there's no match, cancel the operation
					return if adjacentPoints.length is 0
					tiles.selected.push tile
					tiles.generated.push @elements.hexContainer.addTile(
						{tileX: tile.tileX, tileY: tile.tileY}, 'move'
					)
					@elements.hexLine.to tile.x, tile.y
				this
		this
