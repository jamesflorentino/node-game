@Wol

Views = Wol.Views
FrameData =
	marine: {"images": ["marine.png"], "animations": {"onMoveEnd": [17, 23], "onDieStart": [64, 91], "onDefend": [55, 59], "onMoveStart": [1, 3], "onDefendEnd": [60, 63], "all": [0, 0], "onMove": [4, 16], "onDefendStart": [52, 54], "onAttackStart": [24, 51]}, "frames": {"regX": 0, "width": 112, "regY": 0, "height": 97, "count": 92}}


Wol.Units =
	getAnimation: (frameDataName, images) ->
		frameData		= @getFrameData frameDataName, images
		spriteSheet = new SpriteSheet frameData
		animation		= new BitmapAnimation spriteSheet
		animation

	getFrameData: (frameDataName, images) ->
		frameData = FrameData[frameDataName]
		frameData.images = images
		frameData

	createUnitByType: (type) ->
		unit = null
		switch type
			when 'marine'
				unit = new Wol.Views.Marine
			else
				unit = new Wol.Views.Unit
		unit

Units = Wol.Units














# Unit Class
class Wol.Views.Unit extends Wol.Views.View

	init: ->
		@el = new Container()
		@walkSpeed = 100
		@commands = new Wol.Models.Commands
		this
		
	resetCharge: ->
		@model.set charge: 0

	spawn: ->
		tileX = @get 'tileX'
		tileY = @get 'tileY'
		@setTilePosition tileX, tileY
		@resetCharge()
		this

	stand: -> @onStand()

	move: (tiles) ->
		if @get('tileX') is undefined and @get('tileY') is undefined
			@setTilePosition tiles[0].tileX, tiles[0].tileY
			@el.x = tiles[0].x
			@el.y = tiles[0].y
			test = tiles.splice 0, 1
			console.log tiles, test
		@moveThroughTiles tiles
		this

	defend: -> @onDefend()

	hit: -> @onHit()

	performCommand: (commandId) -> @onCommand commandId


	moveThroughTiles: (tiles) =>
		@onMoveStart()
		prevx = @el.x
		tween = Tween.get(@el)
		tiles.forEach (tile, i) =>
			tween = tween.call =>
				@el.scaleX = (if tile.x > prevx then 1 else -1)
				prevx = tile.x
				@onMove()
				this
			tween = tween.to({x:tile.x, y:tile.y}, @walkSpeed)
			@setTilePosition tile.tileX, tile.tileY
			this
		tween = tween.call => @onMoveEnd()
		this

	flip: (facing) ->
		@el.scaleX = (if facing is 'left' then -1 else 1)
		this

	setTilePosition: (tileX, tileY) ->
		@set tileX: tileX, tileY: tileY
		@el.index = tileX + tileY
		this

	play: (frameName)->
		this if !@animation
		@animation.gotoAndPlay frameName
		this

	onStand: -> this
	onMove: -> @trigger 'move'
	onMoveStart: -> this
	onMoveEnd: -> @trigger 'moveEnd'
	onSpawn: -> this
	onHit: -> this
	onDefend: -> this
	onCommand: (commandId) -> this


class Wol.Views.AnimatedUnit extends Wol.Views.Unit

	init: ->
		super()
		@setAnimation()
		@setAnimationEvents()
		@onSpawn()
		this

	setAnimation: ->
		@animation	= Units.getAnimation @frameDataName, @images
		@el.addChild @animation
		@animation.gotoAndStop 0
		this



class Wol.Views.Marine extends Wol.Views.AnimatedUnit

	setAnimation: ->
		@walkSpeed = 600
		@frameDataName = 'marine'
		@images = [
			Wol.getAsset 'marine'
		]
		@commands.add
			name: 'Pulse Rifle Shot'
			code: 'marine_pulserifleshot'
		@el.regX = 30
		@el.regY = 80
		super()

	setAnimationEvents: ->
		@animation.onAnimationEnd = (a, name) =>
			switch name
				when 'onMoveStart'
					a.gotoAndPlay 'onMove'
				when 'onMove'
					a.gotoAndPlay 'onMove'
				when 'onAttackStart'
					@trigger 'attackEnd'
				when 'onDefend'
					this
				when 'onDefendStart'
				else
					a.gotoAndStop 0
			this
		this

	onSpawn: ->
		@animation.gotoAndStop 0

	onStand: ->
		if @defending is true
			@animation.gotoAndPlay 'onDefendEnd'
			@defending = false

	onMoveStart: ->
		@animation.gotoAndPlay 'onMoveStart'

	onMoveEnd: ->
		@animation.gotoAndPlay 'onMoveEnd'
		super()

	onHit: ->
		@animation.gotoAndPlay 'onDefend'

	onDefend: ->
		@defending = true
		@animation.gotoAndPlay 'onDefendStart'

	onCommand: (commandId) ->
		switch commandId
			when 'marine_pulserifleshot'
				@play 'onAttackStart'
				attacks = 4
				while attacks-- > 0
					after 200 * attacks, => @trigger 'attack'
		this


