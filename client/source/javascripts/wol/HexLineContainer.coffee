@Wol

class Wol.Views.HexLineContainer

  constructor: ->
    @el = new Container()
    @lines = new Shape()
    @circle = new Shape()

    @el.addChild @lines
    @el.addChild @circle

  start: (x, y) ->
    lineGraphics = @lines.graphics
    lineGraphics.setStrokeStyle 5
    lineGraphics.beginStroke Graphics.getRGB(0,255,255)
    lineGraphics.moveTo x, y
    @marker x, y

  to: (x, y) ->
    @lines.graphics.lineTo x, y
    @marker x, y

  marker: (x, y) ->
    width = 40
    height = 20
    circleGraphics = @circle.graphics
    circleGraphics.beginFill Graphics.getRGB(0,255,255)
    xx = x - width * 0.5
    yy = y - height * 0.5
    circleGraphics.drawEllipse xx, yy, width, height

  clear: ->
    @lines.graphics.clear()
    @circle.graphics.clear()
