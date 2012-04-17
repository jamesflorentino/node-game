@Wol

{Models, Views, Collections} = @Wol
{Model} = Models
{View} = Views
{Collection} = Collections

class Wol.Views.ActionPoints extends View

  init: ->
    @el = new Container()
    @sheet = new SpriteSheet
      images: [Wol.getAsset 'gauges']
      frames: [
        [0,33,10,18] # background
        [10,33,10,18] # active bar
      ]
    @background = new Container()
    @bars = new Container()
    @el.addChild @background
    @el.addChild @bars
    @imageBar = SpriteSheetUtils.extractFrame @sheet, 1
    @imageBackground = SpriteSheetUtils.extractFrame @sheet, 0

  position: (x, y) ->
    @el.x = x
    @el.y = y
    @el.visible = true
    this

  setValues: (value, total) ->
    @bars.removeAllChildren()
    @background.removeAllChildren()
    # --
    i = 0
    while i < total
      bg = new Bitmap @imageBackground
      bg.x = (@imageBackground.width + 2) * i
      @background.addChild bg
      i++
    i = 0
    # --
    while i < value
      bar = new Bitmap @imageBar
      bar.x = (@imageBar.width + 2) * i
      @bars.addChild bar
      i++
    @el.regX = (@imageBackground.width + 2) * total * 0.5
    @el.regY = @imageBackground.height * 0.5
    this

  deduct: (cost) ->
    children = @bars.getNumChildren()
    index = children - cost
    tilesRemoved = []
    while index < children
      image = @bars.getChildAt index
      tilesRemoved.push image
      index++
    tilesRemoved.each (image) =>
      @bars.removeChild image if image?
    this

  hide: ->
    @el.visible = false
    @bars.removeAllChildren()
    @background.removeAllChildren()
    this
