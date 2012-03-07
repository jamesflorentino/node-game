@Wol

class Wol.Views.HexContainer extends Wol.Views.View

	init: ->
		@el = new Container()
		@__dict = []
		return

	generate: (cols, rows) ->
		tileY = 0
		while tileY < rows
			tileX = 0
			while tileX < cols
				hex = new Wol.Views.HexTile tileX: tileX, tileY: tileY
				hex.show()
				@__dict["tile_#{tileX}_#{tileY}"] = hex
				@el.addChild hex.el
				tileX++
			tileY++
		this
	
	getHexByTilePosition: (tileX, tileY) ->
		hex = @__dict["tile_#{tileX}_#{tileY}"]
		hex

	getTilesByPoints: (points) ->
		tiles = []
		points.forEach (point) =>
			hex = @getTileByPoint point
			tiles.push hex
		tiles
	
	getTileByPoint: (point) -> @__dict["tile_#{point.tileX or point.x}_#{point.tileY or point.y}"]
