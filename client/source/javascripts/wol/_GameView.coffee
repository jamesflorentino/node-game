#= require wol/Ui
#= require wol/HexTile
#= require wol/Unit
#= require wol/HexLineContainer
#= require wol/Commands

@Wol

Views  = Wol.Views
Events = Wol.Events
Units  = Wol.Units

@after = (ms, cb) -> setTimeout cb, ms

class Wol.Views.GameView extends Views.View

	init: ->
		@el = $ @elName
		@canvas= @el.find('canvas')
		@canvas[0].width = @el.width()
		@canvas[0].height = @el.height()
		@stage = new Stage @canvas[0]
		@bindEvents()
		#window.DEBUG = true
		@model.start()

	bindEvents: ->
		@model.bind Events.ASSETS, (e) => @__onAssets e
		@model.bind Events.SPAWN_UNIT, (e) => @__onSpawnUnit e
		@model.bind Events.UNIT_TURN, (e) => @__onUnitTurn e
		@model.bind Events.MOVE_UNIT, (e) => @__onMoveUnit e
		@events =
			tick: (e) => @render e
		return

	setConfigurations: ->
		config	= @model.get 'config'
		@hexList	= []
		@hexContainer.y  =
		@unitContainer.y =
		@terrain.y = config.terrainY

		@hexContainer.x  =
		@unitContainer.x =
		@terrain.x = config.terrainX

		hexImage		= @model.getAsset 'hex'
		gridRows		= config.gridRows
		gridColumns = config.gridColumns
		rowCount		= 0

		# generate Tiles
		while rowCount < gridRows
			colCount = 0
			while colCount < gridColumns
				hex = new Views.HexTile
					tileX: colCount
					tileY: rowCount
					image: hexImage
				@hexList[hex.tileID] = hex
				@hexContainer.addChild hex.el
				colCount++
			rowCount++

		Ticker.useRAF = true
		Ticker.setFPS 30
		Ticker.addListener @events

		if window.DEBUG
			@debug()
		return


	play: ->
		Ticker.setPaused false
		return

	pause: ->
		Ticker.setPaused true
		return

	render: ->
		@stage.update()
		return






	##################################################
	# PUBLIC API
	##################################################

	getHex: (x, y) ->
		@hexList["#{x}|#{y}"]

	addUnit: (unit) ->
		@units or= []
		@units.push unit
		@unitContainer.addChild unit.el
		return

	getUnit: (unitId) ->
		selectedUnit = @units.filter (unit) ->
			return unit.get('id') is unitId
		selectedUnit[0]


	getUnitByTile: (hex) ->
		selectedUnit = @units.filter (unit) ->
			tileX = unit.get 'tileX'
			tileY = unit.get 'tileY'
			tileX is hex.tileX and tileY is hex.tileY

		selectedUnit[0]


	showMoveTiles: (unit) ->
		tileX = unit.get 'tileX'
		tileY = unit.get 'tileY'
		hex = @getHex tileX, tileY
		moveRadius = unit.get 'moveRadius'
		hex.select()
		selectedTiles = []
		tiles = hex.getAdjacentHexPoints radius: moveRadius
		tiles = @getTilesByPoints tiles
		actions = @unitActive.model.get 'actions'
		uiConfirm = @uiConfirm
		uiCancel = @uiCancel
		lineContainer = @lineContainer
		hexContainer = @hexContainer
		lineContainer.start (hexContainer.x + hex.x), (hexContainer.y + hex.y)

		tiles.forEach (tile) =>
			tile.el.onClick = =>

				# show the confirmation box.
				if tile.selected and selectedTiles.last() is tile
					uiConfirm.show (hexContainer.x + tile.x), (hexContainer.y + tile.y)
					return

				# Ignore previously selected tiles.
				return if selectedTiles.indexOf(tile) > -1

				# Return if the unit's action points is depleted
				return if actions is 0
				return if @getUnitByTile(tile)

				# Check if the current tile is adjacent
				# to the last tile selected.
				lastTile = hex
				lastTile = selectedTiles.last() if selectedTiles.length > 0
				surroundingTiles = @getTilesByPoints lastTile.getAdjacentHexPoints()
				return if surroundingTiles.indexOf(tile) is -1


				# Display the tile if it passes all conditions
				selectedTiles.push(tile)
				tile.select()

				lineContainer.to (hexContainer.x + tile.x), (hexContainer.y + tile.y)
				actions--
				return

			tile.show()
			uiCancel.show()

		tileActions =
			deselect: ->
				selectedTiles.forEach (tile) -> tile.deselect()
			hideTiles : ->
				tiles.forEach (tile) -> tile.hide()
			reset: ->
				lineContainer.clear()
				lineContainer.start (hexContainer.x + hex.x), (hexContainer.y + hex.y)

		uiConfirm.bind 'confirm', =>
			uiCancel.hide()
			uiConfirm.hide()
			tiles.forEach (tile) -> tile.hide()
			hex.hide()
			selectedTiles = [hex].concat selectedTiles
			# SENDTOSERVER
			@moveUnit unit, selectedTiles
			return

		uiConfirm.bind 'cancel', =>
			tileActions.reset()
			actions = @unitActive.model.get 'actions'
			tileActions.deselect()
			tileActions.reset()
			selectedTiles = []
			return

		uiCancel.bind 'cancel', =>
			tileActions.hideTiles()
			lineContainer.clear()
			@uiActions.show()
			uiConfirm.hide()
			return
		return

	showUnitCommands: (unit) ->
		uiCommandList = @uiCommandList
		uiCancel = @uiCancel
		uiConfirm = @uiConfirm
		uiActions = @uiActions
		uiCommandList.bind 'act', (command) =>
			uiCommandList.hide()
			tileX = unit.get 'tileX'
			tileY = unit.get 'tileY'
			radius = command.get 'radius'
			centerHex = @getHex tileX, tileY
			tiles = centerHex.getAdjacentHexPoints radius: radius
			@hideSelectedTiles()
			uiCancel.show()
			@selectedTiles = @getTilesByPoints tiles
			@selectedTiles.forEach (tile) =>
				tile.show 'act'
				tile.el.onClick = =>
					targetUnit = @getUnitByTile tile
					return if targetUnit is undefined
					tile.select 'act'
					tilePosition = @getTilePosition tile
					uiConfirm.unbind()
					uiConfirm.show tilePosition.x, tilePosition.y
					uiConfirm.bind 'cancel', => tile.show 'act'
					uiConfirm.bind 'confirm', =>
						uiConfirm.hide()
						uiCancel.hide()
						uiCommandList.hide()
						uiCommandList.unbind()
						@unbindActions()
						@hideSelectedTiles()
						@performAction unit, targetUnit, command
					return
				return
			return

		uiCommandList.bind 'cancel', =>
			@hideSelectedTiles()
			@unbindActions()
			uiActions.show()
			uiCancel.hide()
			uiConfirm.hide()
			return

		uiCancel.bind 'cancel', =>
			@hideSelectedTiles()
			uiCommandList.show()
			uiConfirm.hide()
			return
		uiCommandList.setCommands unit.commands.getCommands()
		return
	
	hideSelectedTiles: ->
		@lineContainer.clear()
		if @selectedTiles
			return if @selectedTiles.length is undefined
			@selectedTiles.forEach (tile) ->
				tile.hide()

	unbindActions: ->
		@uiConfirm.unbind()
		@uiCancel.unbind()
		@uiCommandList.unbind()
		return

	showMenu: ->
		return if !@checkUser()
		unit = @unitActive
		playerId = unit.get 'playerId'
		userId = @model.user.get 'playerId'
		hex = @getHex unit.get('tileX'), unit.get('tileY')
		tilePosition = @getTilePosition hex
		@uiActions.bind 'skip', =>
			hex = @getHex unit.get('tileX'), unit.get('tileY')
			hex.hide()
			@uiActions.unbind()
			@finishAction()
			return

		@uiActions.bind 'act', =>
			@unbindActions()
			@uiCommandList.show tilePosition.x + 20, tilePosition.y - 180
			@showUnitCommands unit
			return

		@uiActions.bind 'move', =>
			@unbindActions()
			@showMoveTiles @unitActive
			return

		@uiActions.show tilePosition.x, tilePosition.y - 170
		return

	getTilePosition: (hex) ->
		x: @hexContainer.x + hex.x
		y: @hexContainer.y + hex.y

	checkUser: ->
		unit = @unitActive
		playerId = unit.get 'playerId'
		userId = @model.user.get 'playerId'
		playerId is userId

	showUnitInfo: (unitId) ->
		unit = @getUnit unitId
		attributes = unit.model.attributes
		@uiUnitInfo.show attributes
		return

	clickTile: (e) ->

		return

	# ---------------------------------------
	# CLIENT TO SERVER Communication Protocol
	# ---------------------------------------
	moveUnit: (unit, tiles) ->
		unitId = unit.get 'id'
		hex = @getHex unit.get('tileX'), unit.get('tileY')
		points = []
		tiles.forEach (tile) ->
			points.push
				x: tile.tileX
				y: tile.tileY

		if window.DEBUG
			@__onMoveUnit
				id: unitId
				points: points
			return

		@model.moveUnit unitId, points
		return

	performAction: (unit, targetUnit, command) ->
		unitId = unit.get 'id'
		targetUnitId = targetUnit.get 'id'
		commandId = command.get 'id'

		if window.DEBUG
			@__onPerformAction
				unitId: unitId
				targetUnitId: targetUnitId
				commandId: commandId
			return

		@model.performAction unitId, targetUnitId, commandId
		return

	finishAction: (mode) ->
		if @unitActive
			unitActive = @unitActive
			hex = @getHex unitActive.get('tileX'), unitActive.get('tileY')
			hex.hide()
		# mode
		# 'act'
		# 'move'
		if window.DEBUG
			@getNextTurn()
			return
		@model.finishAction mode
		return


	# -------------------------------------
	# SERVER COMMANDS
	# -------------------------------------
	getNextTurn: ->
		unitActive = @unitActive
		unitActive.resetCharge() if unitActive?
		units = @units
		unitTurn = null
		# to prevent the loop for going forever
		# by checking if there's a chargeSpeed value in the unit list.
		hasCharge = false
		while !unitTurn
			for unit in units
				chargeSpeed = unit.get 'chargeSpeed'
				randomCharge = Math.random() * 2
				charge = unit.get 'charge'
				charge += chargeSpeed + randomCharge
				charge = 100 if charge > 100
				unit.set charge: charge
				hasCharge = true if chargeSpeed > 0
				unitTurn = unit if charge is 100
				break if unitTurn
			break if !hasCharge
		# perform a predictive calculation of the units' turns.
		# The primary purpose of this data is to populate
		# the turn list UI.
		if unitTurn?
			turnList = []
			total = 10
			while turnList.length < 10
				units.forEach (unit) ->
					charge = unit.get('tempCharge') or unit.get('charge')
					charge += unit.get('chargeSpeed')
					if charge >= 100
						turnList.push
							id: unit.get('id')
							name: unit.get('name')
							playerId: unit.get('playerId')
						charge -= 100 #
					unit.set tempCharge: charge
			@__onUnitTurn
				id: unit.get 'id'
				turnList: turnList
		return

	# -------------------------------------
	# UTiLITY COMMANDS
	# -------------------------------------

	getTilesByPoints: (points) ->
		tiles = []
		points.forEach (point) =>
			tile = @getHex point.x, point.y
			tiles.push tile if tile?
		tiles

	debug: ->
		stats = Wol.Stats.marine()
		stats.tileX = 0
		stats.tileY = 3
		stats.id = String().randomId()
		@__onSpawnUnit stats : stats

		if 1 < 2
			stats = Wol.Stats.marine()
			stats.tileX = 1
			stats.tileY = 3
			stats.id = String().randomId()
			@__onSpawnUnit stats : stats

		@finishAction()
		return



	##################################################
	# CALLBACKS
	##################################################
	__onPerformAction: (data) ->
		unitId = data.unitId
		targetUnitId = data.targetUnitId
		commandId = data.commandId
		unit = @getUnit unitId
		targetUnit = @getUnit targetUnitId
		direction = 'right'
		direction = 'left' if unit.el.x > targetUnit.el.x
		unitEvents =
			attack: ->
				targetUnit.hit()
			attackEnd: =>
				unit.unbind()
				targetUnit.stand()
				@finishAction()
				
		unit.bind 'attack', unitEvents.attack
		unit.bind 'attackEnd', unitEvents.attackEnd
		unit.performCommand commandId
		unit.flip direction
		targetUnit.defend()
		direction = (if direction is 'left' then 'right' else 'left')
		targetUnit.flip direction
		return

	__onMoveUnit: (data) ->
		# note: points are coordinates. not score.
		points = data.points
		unitId = data.id

		unit = @getUnit unitId
		selectedTiles = @getTilesByPoints points
		#unitActive = @unitActive
		unit.bind 'move', =>
			@unitContainer.sortChildren (childA, childB) -> childA.index - childB.index
			return
		unit.bind 'moveEnd', =>
			unit.unbind()
			@lineContainer.clear()
			@finishAction()
			return
		hex = selectedTiles[0]
		unit.move hex.hide()
		unit.move selectedTiles.slice 1, selectedTiles.length

		if !@checkUser()
			@lineContainer.start (@hexContainer.x + hex.x), (@hexContainer.y + hex.y)
			selectedTiles.forEach (tile) =>
				@lineContainer.to (@hexContainer.x + tile.x), (@hexContainer.y + tile.y)
				return
		return


	__onUnitTurn: (data) ->
		unit = @getUnit data.id
		turnList = data.turnList
		hex = @getHex unit.get('tileX'), unit.get('tileY')
		hex.show()
		@unitActive = unit
		@showMenu()
		@uiTurnList.generate turnList
		@showUnitInfo data.id
		return


	__onSpawnUnit: (data) ->
		stats		 = data.stats
		unitType = stats.type
		tileX		 = stats.tileX
		tileY		 = stats.tileY
		unit		 = Units.createUnitByType unitType
		unit.set stats
		unit.flip data.facing
		unit.spawn()
		unit.move @getHex(tileX, tileY)
		@addUnit unit
		return


	__onAssets: (assets) ->
		bitmapBackground = @model.getAsset 'background'
		bitmapTerrain		 = @model.getAsset 'terrain'

		@background = new Bitmap bitmapBackground
		@terrain = new Bitmap bitmapTerrain
		@hexContainer  = new Container()
		@lineContainer = new Wol.HexLineContainer()
		@unitContainer = new Container()
		@uiUnitInfo = new Wol.Ui.UnitInfo()
		@uiActions = new Wol.Ui.Actions()
		@uiConfirm = new Wol.Ui.Confirm()
		@uiTurnList = new Wol.Ui.TurnList()
		@uiCancel = new Wol.Ui.CancelButton()
		@uiCommandList = new Wol.Ui.CommandList()


		@stage.addChild @background
		@stage.addChild @terrain
		@stage.addChild @hexContainer
		@stage.addChild @lineContainer.el
		@stage.addChild @unitContainer

		@setConfigurations()

		return

