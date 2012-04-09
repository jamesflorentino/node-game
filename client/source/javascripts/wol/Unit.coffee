@Wol

Views = Wol.Views
FrameData =
  marine: {"images": ["marine.png"], "frames": {"width": 113, "height": 92, "count": 108, "regX": 0, "regY": 0}, "animations": {"onRifleShot4": [42, 47], "onDieStart": [80, 107], "onRifleShot2": [36, 38], "all": [0, 0], "onRifleShot3": [39, 41], "onRifleShotEnd": [48, 58], "onDefend": [66, 70], "onDefendEnd": [71, 79], "onMoveEnd": [16, 22], "onDefendStart": [59, 65], "onRifleShotStart": [23, 29], "onMoveStart": [1, 3], "onMove": [4, 15], "onRifleShot1": [30, 35]}}

  marine_alternate: {"images": ["marine_alternate.png"], "frames": {"width": 113, "height": 92, "count": 108, "regX": 0, "regY": 0}, "animations": {"onMove": [4, 15], "onRifleShot1": [30, 35], "onDefendEnd": [71, 79], "onMoveStart": [1, 3], "onMoveEnd": [16, 22], "onRifleShot4": [42, 47], "onDefend": [66, 70], "all": [0, 0], "onRifleShot2": [36, 38], "onDefendStart": [59, 65], "onRifleShotStart": [23, 29], "onDieStart": [80, 107], "onRifleShot3": [39, 41], "onRifleShotEnd": [48, 58]}}

Wol.Units =
  getAnimation: (frameDataName, images) ->
    frameData   = @getFrameData frameDataName, images
    spriteSheet = new SpriteSheet frameData
    animation   = new BitmapAnimation spriteSheet
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

class Wol.Models.Commands extends Wol.Collections.Collection
  init: ->

# Unit Class
class Wol.Views.Unit extends Wol.Views.View

  commands: null
  walkSpeed: 100
  el: new Container()
  height: 150
  init: ->
    @el = new Container()
    @walkSpeed = 100
    @commands = new Wol.Models.Commands()
    this

  resetCharge: ->
    @model.set charge: 0

  spawn: ->
    tileX = @get 'tileX'
    tileY = @get 'tileY'
    @setTilePosition tileX, tileY
    @resetCharge()
    this

  getStat: (statName) -> @get statName

  stand: -> @onStand()

  move: (tiles) ->
    tiles = [].concat tiles
    # to ensure that if a unit has no tileX and tileY properties,
    # it will immediately state them during the start of this function.
    if @get('tileX') is undefined and @get('tileY') is undefined
      @setTilePosition tiles[0].tileX, tiles[0].tileY
      @el.x = tiles[0].x
      @el.y = tiles[0].y
      tiles.splice 0, 1
    @moveThroughTiles tiles
    this

  act: (data) -> @onAct data

  defend: -> @onDefend()

  defendEnd: -> @onDefendEnd()

  hit: -> @onHit()

  die: -> @onDie()

  performCommand: (commandId) -> @onCommand commandId

  moveThroughTiles: (tiles) =>
    @onMoveStart()
    prevx = @el.x
    tween = Tween.get(@el)
    tiles.forEach (tile, i) =>
      return if i is 0
      @setTilePosition tile.tileX, tile.tileY
      tween = tween.call =>
        @el.scaleX = (if tile.x > prevx then 1 else -1)
        prevx = tile.x
        @onMove()
        this
      tween = tween.to({x:tile.x, y:tile.y}, @walkSpeed)
    tween = tween.call => @onMoveEnd()
    this

  flip: (facing) ->
    @el.scaleX = (if facing is 'left' then -1 else 1)
    this

  setTilePosition: (tileX, tileY) ->
    @set tileX: tileX, tileY: tileY
    @el.depth = tileX + tileY
    this

  play: (frameName)->
    this if !@animation
    @animation.gotoAndPlay frameName
    this

  onStand: -> this
  onMove: -> @trigger 'move'
  onMoveStart: -> this
  onMoveEnd: -> @trigger 'moveUnitEnd'
  onSpawn: -> this
  onHit: -> this
  onDie: -> @trigger 'die'
  onDefend: -> this
  onDefendEnd: ->
  onCommand: (commandId) -> this


class Wol.Views.AnimatedUnit extends Wol.Views.Unit

  init: ->
    super()
    @setAnimation()
    @setAnimationEvents()
    @onSpawn()
    this

  setAnimation: ->
    @animation  = Units.getAnimation @frameDataName, @images
    @el.addChild @animation
    @animation.gotoAndStop 0
    this

  showLastKeyFrame: (a, frameName) ->
    currentFrame = a.currentFrame
    animationLength = a.spriteSheet.getNumFrames frameName
    a.gotoAndStop(currentFrame + animationLength - 1)
    this


class Wol.Views.Marine extends Wol.Views.AnimatedUnit

  setAnimation: ->
    @height = 125
    @walkSpeed = 600
    assetName = 'marine'
    assetName = 'marine_alternate' if @alternateColor is true
    @frameDataName = assetName
    @images = [
      Wol.getAsset assetName
    ]
    @el.regX = 30
    @el.regY = 87
    super()

  setAnimationEvents: ->
    @animation.onAnimationEnd = (a, name) =>
      switch name
        when 'onMoveStart'
          a.gotoAndPlay 'onMove'
        when 'onMove'
          a.gotoAndPlay 'onMove'
        when 'onDefendStart'
          @showLastKeyFrame a, name
        when 'onDefend'
          a.paused = true
        when 'onRifleShotStart'
          a.gotoAndPlay 'onRifleShot1'
          @trigger 'attack', multiplier: 0.25
        when 'onRifleShot1'
          a.gotoAndPlay 'onRifleShot2'
          @trigger 'attack', multiplier: 0.25
        when 'onRifleShot2'
          a.gotoAndPlay 'onRifleShot3'
          @trigger 'attack', multiplier: 0.25
        when 'onRifleShot3'
          a.gotoAndPlay 'onRifleShot4'
          @trigger 'attack', multiplier: 0.25
        when 'onRifleShot4'
          a.gotoAndPlay 'onRifleShotEnd'
          @trigger 'attackEnd'
        when 'onDieStart'
          @showLastKeyFrame a, name
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

  onAct: (data) ->
    {commandCode} = data
    switch commandCode
      when 'grenade'
      else
        @animation.gotoAndPlay 'onRifleShotStart'
    this


  onHit: ->
    @animation.gotoAndPlay 'onDefend'

  onDie: ->
    @animation.gotoAndPlay 'onDieStart'
    super()

  onDefend: ->
    #@defending = true
    @animation.gotoAndPlay 'onDefendStart'

  onDefendEnd: ->
    #@defending = false
    @animation.gotoAndPlay 'onDefendEnd'
