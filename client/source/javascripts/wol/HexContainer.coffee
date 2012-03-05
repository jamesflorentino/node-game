@Wol

class Wol.Views.HexContainer extends Wol.Views.View

	init: ->
		@el = new Container()
		return

	generate: (cols, rows) ->
		yy = 0
		while yy < rows
			xx = 0
			while xx < cols
				hex = new Wol.Views.HexTile tileX: xx, tileY: yy
				@el.addChild hex.el
				xx++
			yy++
		this

