@Wol

getIntersectHexes = (x, y, radius = 1, gap = 0) ->
	tiles = []
	i = 1 + gap

	while i < radius + 1
		list = getEast x, y, i, true
		tiles = tiles.concat list

		list = getSouthEast x, y, i, true
		tiles = tiles.concat list
			
		list = getSouthWest x, y, i, true
		tiles = tiles.concat list

		list = getWest x, y, i, true
		tiles = tiles.concat list

		list = getNorthWest x, y, i, true
		tiles = tiles.concat list

		list = getNorthEast x, y, i, true
		tiles = tiles.concat list
		i++
	tiles

getConeHexes = (x, y, radius = 1, gap = 0) ->
	tiles = []
	i = 1 + gap

	while i < radius + 1
		list = getEast x, y, i
		tiles = tiles.concat list

		list = getSouthEast x, y, i, true
		tiles = tiles.concat list
			
		list = getSouthWest x, y, i, false
		tiles = tiles.concat list

		list = getWest x, y, i, false
		tiles = tiles.concat list

		list = getNorthWest x, y, i, true
		tiles = tiles.concat list

		list = getNorthEast x, y, i
		tiles = tiles.concat list
		i++
	tiles


getLinearHexes = (x, y, radius = 1, gap = 0) ->
	tiles = []
	i = 1 + gap
	while i < radius + 1
		list = getEast x, y, i, true
		tiles = tiles.concat list

		list = getWest x, y, i, true
		tiles = tiles.concat list
		i++
	tiles

getAdjacentHexes = (x, y, radius = 1, gap = 0) ->
	tiles = []
	i = 1 + gap
	while i < radius + 1
		list = getSouthEast x, y, i
		tiles = tiles.concat list

		list = getNorthEast x, y, i
		tiles = tiles.concat list

		list = getSouthWest x, y, i
		tiles = tiles.concat list

		list = getNorthWest x, y, i
		tiles = tiles.concat list

		list = getWest x, y, i
		tiles = tiles.concat list
		
		list = getEast x, y, i
		tiles = tiles.concat list

		i++

	tiles

getEast = (x, y, radius, skipIteration) ->
	tiles = []
	i = 0
	offsetX = radius * 0.5
	offsetX = Math.floor offsetX
	while i < radius
		yy = y + i
		xx = x + radius - Math.ceil(i * 0.5)
		xx++ if y % 2 and yy % 2 is 0
		tiles.push
			x: xx
			y: yy
		i++
		break if skipIteration
	tiles

getWest = (x, y, radius, skipIteration) ->
	tiles = []
	i = 0
	offsetX = radius * 0.5
	offsetX = Math.floor offsetX
	while i < radius
		yy = y - i
		xx = x - radius + Math.floor(i * 0.5)
		xx++ if y % 2 and yy % 2 is 0
		tiles.push
			x: xx
			y: yy
		i++
		break if skipIteration
	tiles

getNorthWest = (x, y, radius, skipIteration) ->
	tiles = []
	i = 0
	offsetX = radius * 0.5
	offsetX = Math.ceil offsetX
	while i < radius
		xx = x + i - offsetX
		yy = y - radius
		xx++ if y % 2 and radius % 2
		tiles.push
			x: xx
			y: yy
		break if skipIteration
		i++

	tiles

getSouthWest = (x, y, radius, skipIteration) ->
	tiles = []
	i = 0
	offsetX = radius * 0.5
	offsetX = Math.ceil offsetX
	while i < radius
		yy = y + radius - i
		xx = x - i - offsetX + Math.ceil(i * 0.5)
		xx++ if yy % 2 is 0 and y % 2 and radius % 2
		xx-- if radius % 2 is 0 and y % 2 is 0 and yy % 2
		tiles.push
			x: xx
			y: yy
		break if skipIteration
		i++
	tiles

getNorthEast = (x, y, radius, skipIteration) ->
	tiles = []
	i = 0
	offsetX = radius * 0.5
	offsetX = Math.floor offsetX
	while i < radius
		yy = y - radius + i
		xx = x + i + offsetX - Math.floor(i * 0.5)
		xx++ if yy % 2 is 0 and y % 2 and radius % 2
		xx-- if radius % 2 is 0 and y % 2 is 0 and yy % 2
		tiles.push
			x: xx
			y: yy
		i++
		break if skipIteration
	tiles

getSouthEast = (x, y, radius, skipIteration) ->
	tiles = []
	i = 0
	offsetX = radius * 0.5
	offsetX = Math.floor offsetX
	while i < radius
		xx = x - i + offsetX
		yy = y + radius
		xx++ if y % 2 and radius % 2
		tiles.push
			x: xx
			y: yy
		i++
		break if skipIteration
	tiles



width = 126
height = 86
offsetX = 63
offsetY = 22


class Wol.Views.HexTile extends Wol.Views.View

	init: ->
		@__base	= new Bitmap Wol.getAsset 'hex'
		@__move = new Bitmap Wol.getAsset 'hex_move'
		@__act	= new Bitmap Wol.getAsset 'hex_act'
		@__target = new Bitmap Wol.getAsset 'hex_act_target'
		@el			= new Container()
		@tileID = "#{@tileX}|#{@tileY}"
		@el.x		= width * @tileX
		@el.y		= (height - offsetY) * @tileY
		@width	= width
		@height = height
		@el.x += offsetX if @tileY % 2
		@x = @el.x + width * 0.5
		@y = @el.y + height * 0.5

		@el.addChild @__base
		@el.addChild @__act
		@el.addChild @__move
		@el.addChild @__target

		@hide()

		@cost = 1
		return

	select: (mode) ->
		@show()
		@selected = true
		@__hideTiles()
		switch mode
			when 'act'
				@__target.visible = true
			else
				@__move.visible = true
		return

	deselect: ->
		@selected = false
		@__base.visible = true
		@__move.visible = false
		@__target.visible = false

	hide: ->
		@el.visible = false
		@selected = false
		@el.onClick = null
		return

	__hideTiles: ->
		@__move.visible = false
		@__base.visible = false
		@__act.visible = false
		@__target.visible = false
		return

	show: (mode = 'move') ->
		@el.visible			= true
		@__hideTiles()
		switch mode
			when 'act'
				@__act.visible = true
			else
				@__base.visible	= true
		return

	addUnit: (unit) ->
		@units or= []
		@units.push unit
		return

	removeUnit: (unit) ->
		@units or= []
		@units.splice(@units.indexOf(unit), 1)
		return

	getAdjacentHexPoints: (params) ->
		params or= {}
		radius = params.radius or 1
		tiles = getAdjacentHexes @tileX, @tileY, radius
		tiles or= []


