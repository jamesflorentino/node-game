@Wol

# ============================================
# FrameData
# ============================================
Views = Wol.Views
FrameData =
  marine: {"images": ["marine.png"],"frames": {"width": 113, "height": 97, "count": 123, "regX": 0, "regY": 0},"animations": {"onRifleShot2": [55, 57], "onRifleShot3": [58, 60], "standUp": [1, 10], "onDefendEnd": [90, 98], "all": [0, 0], "onDieStart": [99, 122], "onMoveStart": [20, 22], "onDefend": [85, 89], "onMove": [23, 34], "onDefendStart": [78, 84], "onRifleShot1": [49, 54], "onRifleShotStart": [42, 48], "onMoveEnd": [35, 41], "onRifleShot4": [61, 66], "standDown": [11, 19], "onRifleShotEnd": [67, 77]}}


  marine_alternate: {"images":["marine_alternate.png"],"frames":{"width":113,"height":97,"regX":0,"count":123,"regY":0},"animations":{"onRifleShot3":[58,60],"onRifleShot2":[55,57],"onMoveStart":[20,22],"onDieStart":[99,122],"standDown":[11,19],"all":[0,0],"onRifleShot1":[49,54],"onDefendEnd":[90,98],"onDefend":[85,89],"onMoveEnd":[35,41],"onDefendStart":[78,84],"onRifleShotStart":[42,48],"onRifleShotEnd":[67,77],"standUp":[1,10],"onMove":[23,34],"onRifleShot4":[61,66]}}


# ============================================
# ============================================
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
        unit = new Wol.Views.Marine()
      else
        unit = new Wol.Views.Unit()
    unit

Units = Wol.Units

# Unit Class
class Wol.Views.Unit extends Wol.Views.View

  commands: null
  walkSpeed: 100
  el: new Container()
  height: 150
  init: ->
    @el = new Container()
    @dead = false
    @walkSpeed = 100
    @commands = new Wol.Collections.Collection()
    # do not implement for now.. To buggy.
    ###
    @el.onClick = =>
      if @el.selected is true
        Tween.get(@el).to(
          scaleX: 1 * Math.abs(@el.scaleX) / @el.scaleX,
          scaleY: 1
        ,
          400
        ,
          Ease.backOut
        )
        @el.selected = false
      else
        Tween.get(@el).to(
          scaleX: 1.2 * Math.abs(@el.scaleX) / @el.scaleX,
          scaleY: 1.2
        ,
          400
        ,
          Ease.backInOut
        )
        @el.selected = true
    ###
    this

  resetCharge: ->
    @model.set charge: 0

  spawn: ->
    tileX = @get 'tileX'
    tileY = @get 'tileY'
    @setTilePosition tileX, tileY
    @resetCharge()
    @trigger 'spawn'
    this

  getStat: (statName) -> @get('unitStats')[statName]

  setStat: (data) ->
    stats = @get 'unitStats'
    for prop of data
      stats[prop] = data[prop]

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

  defend: ->
    return if @dead is true
    @onDefend()

  defendEnd: ->
    return if @dead is true
    @onDefendEnd()

  hit: ->
    return if @dead is true
    @onHit()

  die: ->
    @dead = true
    @onDie()

  remove: ->
    @onRemove()

  position: (x, y) ->
    @el.x = x
    @el.y = y

  performCommand: (commandId) -> @onCommand commandId

  moveThroughTiles: (tiles) =>
    @onMoveStart()
    prevx = @el.x
    tween = Tween.get @el
    tiles.forEach (tile, i) =>
      return if i is 0
      @setTilePosition tile.tileX, tile.tileY
      tween = tween.call =>
        @el.scaleX = (if tile.x > prevx then 1 else -1)
        prevx = tile.x
        @onMove x: tile.x, y: tile.y, speed: @walkSpeed
        return
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
    @animating = true
    @animation.gotoAndPlay frameName
    this

  onStand: -> this
  onMove: (data) -> @trigger 'move', data
  onMoveStart: -> this
  onMoveEnd: -> @trigger 'moveUnitEnd'
  onSpawn: -> this
  onHit: -> this
  onDie: -> @trigger 'die'
  onDefend: -> this
  onDefendEnd: -> this
  onCommand: (commandId) -> this
  onRemove: ->
    @el.visible = false


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

  showLastKeyFrame: (animation, frameName) ->
    currentFrame = animation.currentFrame
    animationLength = animation.spriteSheet.getNumFrames frameName
    lastFrame = currentFrame + animationLength - 1
    animation.gotoAndStop(currentFrame + animationLength - 1)
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
    @el.regX = 32
    @el.regY = 77
    super()

  setAnimationEvents: ->
    @animation.onAnimationEnd = (a, name) =>
      @animating = false
      switch name
        when 'onMoveStart'
          @play 'onMove'
        when 'onMove'
          @play 'onMove'
        when 'onDefendStart'
          @showLastKeyFrame a, name
        when 'onDefend'
          a.paused = true
        when 'onRifleShotStart'
          @play 'onRifleShot1'
          @trigger 'attack', multiplier: 0.25
        when 'onRifleShot1'
          @play 'onRifleShot2'
          @trigger 'attack', multiplier: 0.25
        when 'onRifleShot2'
          @play 'onRifleShot3'
          @trigger 'attack', multiplier: 0.25
        when 'onRifleShot3'
          @play 'onRifleShot4'
          @trigger 'attack', multiplier: 0.25
        when 'onRifleShot4'
          @play 'onRifleShotEnd'
          @trigger 'attackEnd'
        when 'onDieStart'
          @showLastKeyFrame a, name
        when 'standUp'
          @play 'standDown'
        when 'standDown'
          @showLastKeyFrame a, name
          after 1000 + Math.random() * 5 * 100, =>
            @play 'standUp' if @animating is false
        else
          @play 'standUp'
      this
    this

  onSpawn: ->
    if Math.random() > .5 then @play 'standUp' else @play 'standDown'

  onStand: ->
    if @defending is true
      @play 'onDefendEnd'
      @defending = false

  onMoveStart: ->
    @play 'onMoveStart'

  onMoveEnd: ->
    @play 'onMoveEnd'
    super()

  onAct: (data) ->
    {commandCode} = data
    switch commandCode
      when 'grenade'
      else
        @play 'onRifleShotStart'
    this

  onHit: ->
    @play 'onDefend'

  onDie: ->
    @play 'onDieStart'
    super()

  onDefend: ->
    @play 'onDefendStart'

  onDefendEnd: ->
    @play 'onDefendEnd'

  onRemove: ->
    Tween.get(@el)
      .to(
        {alpha: 0}
      , 400
      ).call(=>
        @el.visible = false
      )
