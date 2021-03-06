@Wol


width = 126
height = 86
offsetX = 63
offsetY = 22

WIDTH = 126
HEIGHT = 86
OFFSETX = 63
OFFSETY = 22

class Wol.Views.Hex extends Wol.Views.View

  x: 0
  y: 0
  width: 126
  height: 86
  offsetX: 63
  offsetY: 22
  cost: 1
  tileX: 0
  tileY: 0

  # i overrode this one because we don't want the
  # constuctor to assign the arguments as properties
  # of the object class.
  constructor: (options) ->
    @show options

  # self () options
  # options accepts 2 kinds of attributes
  # assetName - the bitmap asset of the targetted unit
  # point - the tile object position
  show: (options) ->
    {assetName} = options
    {point} = options
    type = switch assetName
      when 'move' then 'hex_move'
      when 'act' then 'hex_act'
      when 'target' then 'hex_act_target'
      else 'hex'
    @el = new Bitmap Wol.getAsset type
    # the correct property should be `point.tileX` and `point.tileY`,
    # but since I'm doing a pre-calculation of adjacent tiles, I should
    # also check for the `point.x` and `point.y` properties.
    @tileX = (if point.x is undefined then point.tileX else point.x)
    @tileY = (if point.y is undefined then point.tileY else point.y)
    @el.x = @width * @tileX
    @el.y = (@height - @offsetY) * @tileY
    @el.x += @offsetX if @tileY % 2
    @x = @el.x + @width * 0.5
    @y = @el.y + @height * 0.5
    @id = "#{@tileX}_#{@tileY}"
    @el.onClick = => @trigger 'click', this
    this

  hide: ->
    @el.visible = false
    @trigger 'hide'
    this

  getAdjacentPoints: (params) ->
    radius = 1
    format = 0 # 0 - array, 1 - string
    if params?
      radius = params.radius or radius
      format = params.format or format
    result = HexUtil.getAdjacentHexes @tileX, @tileY, radius
    result or= []
    switch format
      when 1 # array with strings
        return (->
          arr = []
          result.forEach (tile) ->
            arr.push tile.id
          arr
        )()
      else
        return result

  click: (cb) -> @bind 'click', cb

  removeClick: (cb) -> @unbind 'click', cb
  
  getCoordinates: (tileX, tileY) ->
    x = @width * tileX
    y = (@height - @offsetY) * tileY
    x += @offsetX if tileY % 2
    x = x + @width * 0.5
    y = y + @height * 0.5
    x: x, y: y


