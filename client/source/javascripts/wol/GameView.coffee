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
		@canvas.width = 980
		@canvas.height = 700
		@stage = new Stage @canvas
		@pause()
		Ticker.addListener tick: => @render()
	
	useRAF: ->
		Ticker.useRAF = true
		Ticker.setFPS 30
	
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
			unitContainer: new Wol.Views.UnitContainer()
			viewport: new Container()

		@elements.viewport.addChild @elements.terrain
		@elements.viewport.addChild @elements.hexContainer.el
		@elements.viewport.addChild @elements.unitContainer.el

		# Initiate the UI elements
		# putting them into a namespace will make it easy to remember
		@ui =
			cancelButton: new Wol.Ui.CancelButton()
			commandList: new Wol.Ui.CommandList()
			unitInfo: new Wol.Ui.UnitInfo()
			turnList: new Wol.Ui.TurnList()
			actionMenu: new Wol.Ui.ActionMenu()
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
		# generate the grid
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
		@model.bind 'startGame', @startGame
		@model.bind 'addUnit', @addUnit
		@model.bind 'moveUnit', @moveUnit
		@model.connect()
		@startGame()
		this
	
	startGame: =>
		@play()
		return

	addUnit: (data) =>
		console.log 'addUnit', data
		unitId = data.unitId
		unitCode = data.unitCode
		unit = @elements.unitContainer.createUnitByCode unitCode
		unit.set data
		@elements.unitContainer.addUnit unit
		this
	
	moveUnit: (data) =>
		unitId = data.unitId
		unit = @elements.unitContainer.getUnitById unitId
		tiles = @elements.hexContainer.getTilesByPoints data.points
		unit.move tiles
		this

