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

# calculation of the shortest distance to the target area.
getHeuristics = (start, destination) ->
  # the manhattan distance
  # Math.abs(start.x - destination.x) + Math.abs(start.y - destination.y)
  # the euclidean distance
  #Math.sqrt(Math.pow(start.x - destination.x, 2)) + Math.pow(start.x - destination.y, 2)
  Math.sqrt(Math.pow((start.x - destination.x), 2) + Math.pow((start.y - destination.y), 2))
 
getAdjacentPoints = (origin) ->
  getAdjacentHexes origin.x, origin.y

setBounds = (points, columns, rows) ->
  point for point in points when point.x > -1 and point.y > -1 and point.x < columns and point.y < rows

window.HexUtil =
  getAdjacentHexes: getAdjacentHexes
  getHeuristics: getHeuristics
  getAdjacentPoints: getAdjacentPoints
  setBounds: setBounds
