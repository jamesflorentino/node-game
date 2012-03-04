@Wol

Views = Wol.Views
FrameData =
  marine: {"images": ["marine.png"], "animations": {"onMoveEnd": [17, 23], "onDieStart": [64, 91], "onDefend": [55, 59], "onMoveStart": [1, 3], "onDefendEnd": [60, 63], "all": [0, 0], "onMove": [4, 16], "onDefendStart": [52, 54], "onAttackStart": [24, 51]}, "frames": {"regX": 0, "width": 112, "regY": 0, "height": 97, "count": 92}}





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














# Unit Class
class Wol.Views.Unit extends Wol.Views.View

  init: ->
    @el = new Container()
    @walkSpeed = 100
    @commands = new Wol.Models.Commands
    return
    
  resetCharge: ->
    @model.set charge: 0
    return

  spawn: ->
    tileX = @get 'tileX'
    tileY = @get 'tileY'
    @setTilePosition tileX, tileY
    @resetCharge()
    return


  stand: -> @onStand()

  move: (params) ->
    if params instanceof Views.HexTile
      hex = params
      @el.x = hex.x
      @el.y = hex.y
    if params instanceof Array
      @moveThroughTiles params
    return

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
        return
      tween = tween.to({x:tile.x, y:tile.y}, @walkSpeed)
      @setTilePosition tile.tileX, tile.tileY
      return
    tween = tween.call => @onMoveEnd()
    return

  flip: (facing) ->
    @el.scaleX = (if facing is 'left' then -1 else 1)
    return

  setTilePosition: (tileX, tileY) ->
    @set tileX: tileX, tileY: tileY
    @el.index = tileX + tileY
    return

  play: (frameName)->
    return if !@animation
    @animation.gotoAndPlay frameName
    return

  onStand: -> return
  onMove: -> @trigger 'move'
  onMoveStart: -> return
  onMoveEnd: -> @trigger 'moveEnd'
  onSpawn: -> return
  onHit: -> return
  onDefend: -> return
  onCommand: (commandId) -> return


class Wol.Views.AnimatedUnit extends Wol.Views.Unit

  init: ->
    super()
    @setAnimation()
    @setAnimationEvents()
    @onSpawn()
    return

  setAnimation: ->
    @animation  = Units.getAnimation @frameDataName, @images
    @el.addChild @animation
    @animation.gotoAndStop 0
    return



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
          return
        when 'onDefendStart'
        else
          a.gotoAndStop 0
      return
    return

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
    return


