@Wol


class Wol.Views.HexContainer extends Wol.Views.View

  init: ->
    @el = new Container()
    @background = new Container()
    @__dict = []
    @tiles = []
    @set
      selection:
        move: undefined
        selected: undefined
        generated: undefined
        adjacent: undefined
    return
  
  removeSelectionTiles: ->
    tiles = @get 'selection'
    @removeTiles tiles.move if tiles.move?
    @removeTiles tiles.selected if tiles.selected?
    @removeTiles tiles.generated if tiles.generated?

  # generate a cached version of the tiles.
  # These does not udpate very much often
  generate: (cols, rows) ->
    tileY = 0
    while tileY < rows
      tileX = 0
      while tileX < cols
        @addBackgroundTile tileX, tileY
        tileX++
      tileY++
    # get the tentative total width and height of the hex grid
    # we need to cache the image so that we dont re-draw the grid
    # every tick to save up CPU usage.
    totalWidth = Wol.Views.Hex::width * cols + Wol.Views.Hex::offsetX
    totalHeight = (Wol.Views.Hex::height - Wol.Views.Hex::offsetY) * rows
    totalHeight += Wol.Views.Hex::offsetY
    @background.cache 0, 0, totalWidth, totalHeight
    this
  
  addBackgroundTile: (tileX, tileY) ->
    hex = new Bitmap Wol.getAsset 'hex_bg'
    hex.x = Wol.Views.Hex::width * tileX
    hex.y = (Wol.Views.Hex::height - Wol.Views.Hex::offsetY) * tileY
    hex.x += Wol.Views.Hex::offsetX if tileY % 2
    hex.onClick = => @trigger 'hex', "#{tileX}_#{tileY}"
    @background.addChild hex


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
    return if (point.tileX or point.x) < 0 or (point.tileX or point.x) >= Wol.Settings.columns
    return if (point.tileY or point.y) < 0 or (point.tileY or point.y) >= Wol.Settings.rows
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

  convertToPoints: (tiles) ->
    tiles.map (tile) ->
      x: tile.tileX
      y: tile.tileY

  setActiveTile: (tile) ->
    @removeActiveTile()
    @set activeTile: tile

  removeActiveTile: ->
    @removeTile @get('activeTile')

  toPoint: (tileId) ->
    r = tileId.split('_')
    x: Number(r[0]), y: Number(r[1])

  isValid: (p) ->
    (p.x > -1 and p.y > -1) and
    (p.y < Wol.Settings.columns and p.y < Wol.Settings.rows)

