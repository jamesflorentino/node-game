Wol = @Wol

{Views} = Wol

class Views.DamageCounter extends Views.View
  life: 500
  paddingX: 1
  radiusX: 50
  radiusY: 25
  init: ->
    @el = new Container()
    @sheet = new SpriteSheet
      images: [Wol.getAsset('damage')]
      frames: [
        [0,0,18,16] # 0
        [18,0,9,16] # 1
        [27,0,18,16] # 2
        [45,0,18,16] # 3
        [63,0,18,16] # 4
        [81,0,18,16] # 5
        [99,0,19,16] # 6
        [118,0,17,16] # 7
        [135,0,17,16] # 8
        [152,0,17,16] # 9
      ]
    @chars =
      "0": 0
      "1": 1
      "2": 2
      "3": 3
      "4": 4
      "5": 5
      "6": 6
      "7": 7
      "8": 8
      "9": 9
    this

  show: (data) ->
    {x,y,damage} = data

    angle = Math.random() * 360
    radian =  angle * Math.PI / 180
    x += Math.sin(radian) * @radiusX
    y += Math.cos(radian) * @radiusY
    x -= 10

    frameImages = []
    damage = Math.round damage
    chars = damage.toString().split ""
    chars.each (char, i) =>
      charIndex = @getIndexByChar char
      frame = SpriteSheetUtils.extractFrame @sheet, charIndex
      return if !frame
      rect = @sheet.getFrame(charIndex).rect
      image = new Bitmap frame
      image.x = x
      image.y = y + rect.height * 2
      image.visible = false
      image.snapToPixel = true
      Tween.get(image)
        .wait(60 * i)
        .call(-> image.visible = true)
        .to({y:y}, 300, Ease.backOut)
        .wait(@life)
        .to({alpha: 0, y: y - frame.height}, 400, Ease.backIn)
      x += rect.width
      frameImages.push image
      @el.addChild image


  getIndexByChar: (char) ->
    @chars[char]
