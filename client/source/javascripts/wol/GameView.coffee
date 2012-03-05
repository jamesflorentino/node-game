#= require wol/AssetLoader
#= require wol/Ui
#= require wol/HexTile
#= require wol/Unit
#= require wol/HexContainer
#= require wol/HexLineContainer
#= require wol/Commands


# ========================================
# NOTES
# ========================================
# - if you want to validate tile movement,
# - calculate the unit's total AP and compare

@Wol

class Wol.Views.GameView extends Wol.Views.View

	init: ->
		@canvas = document.getElementById('game').getElementsByTagName('canvas')[0]
		@canvas.width = 980
		@canvas.height = 700
		assetLoader = new Wol.AssetLoader
		assetLoader.download Wol.AssetList, (item) =>
			@buildElements()
				.assignEvents()
				.setConfigurations()
				.play()
			return

		# assign the method to the Wol namespace for easy access
		Wol.getAsset = (name) -> assetLoader.get name
		return

	buildElements: ->
		# the `root` of the entire canvas
		@stage = new Stage @canvas

		# canvas Layers
		@elements =
			background: new Bitmap Wol.getAsset 'background'
			terrain: new Bitmap Wol.getAsset 'terrain'
			hexContainer: new Wol.Views.HexContainer()

		# Initiate the UI elements
		@ui =
			cancelButton: new Wol.Ui.CancelButton()
			commandList: new Wol.Ui.CommandList()
			unitInfo: new Wol.Ui.UnitInfo()
			turnList: new Wol.Ui.TurnList()
			actionMenu: new Wol.Ui.ActionMenu()

		# add the elements to the stage
		@stage.addChild @elements.background
		@stage.addChild @elements.terrain
		@stage.addChild @elements.hexContainer.el

		this
	
	setConfigurations: ->
		@elements.terrain.x = @elements.hexContainer.el.x = Wol.Settings.terrainX
		@elements.terrain.y = @elements.hexContainer.el.y = Wol.Settings.terrainY
		@elements.hexContainer.generate Wol.Settings.columns, Wol.Settings.rows
		this

	assignEvents: ->
		Ticker.addListener tick: => @render()
		this
	
	play: ->
		Ticker.setPaused false
		after 1000, => @pause()
		this
	
	pause: ->
		Ticker.setPaused true
		this

	render: ->
		@stage.update()
		this
