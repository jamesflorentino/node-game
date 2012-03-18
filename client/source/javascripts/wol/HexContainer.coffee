@Wol


class Wol.Views.HexContainer extends Wol.Views.View

  init: ->
    @el = new Container()
    @background = new Container()
    @__dict = []
    @tiles = []
    @set
      move: undefined
      selected: undefined
      generated: undefined
      adjacent: undefined
    return

  # generate a cached version of the tiles.
  # These does not udpate very much often
  generate: (cols, rows) ->
    tileY = 0
    while tileY < rows
      tileX = 0
      while tileX < cols
        hex = new Bitmap Wol.getAsset 'hex_bg'
        hex.x = Wol.Views.Hex::width * tileX
        hex.y = (Wol.Views.Hex::height - Wol.Views.Hex::offsetY) * tileY
        hex.x += Wol.Views.Hex::offsetX if tileY % 2
        @el.addChild hex
        tileX++
      tileY++
    # get the tentative total width and height of the hex grid
    # we need to cache the image so that we dont re-draw the grid
    # every tick to save up CPU usage.
    totalWidth = Wol.Views.Hex::width * cols + Wol.Views.Hex::offsetX
    totalHeight = (Wol.Views.Hex::height - Wol.Views.Hex::offsetY) * rows
    @background.cache 0, 0, totalWidth, totalHeight
    this

  addTilesByPoints: (points, assetName) ->
    tiles = []
    points.forEach (point) =>
      tile = @addTile point, assetName
      tiles.push tile if tile?
    tiles
  
  removeTiles: (tiles) ->
    tiles.forEach (tile) => @removeTile tile
    this

  addTile: (point, assetName) ->
    return if (point.tileX or point.x) < 0 or (point.tileX or point.x) > Wol.Settings.columns
    return if (point.tileY or point.y) < 0 or (point.tileY or point.y) > Wol.Settings.rows
    hex = new Wol.Views.Hex
      assetName: assetName
      point: point
    @tiles.push hex
    @el.addChild hex.el
    hex
  
  removeTile: (tile) ->
    index = @tiles.indexOf tile
    if index > -1
      @el.removeChild tile.el
      @tiles.splice index, 1
    this
  

