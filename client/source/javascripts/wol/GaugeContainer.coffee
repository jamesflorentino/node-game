@Wol

{Views, Models, Collections} = Wol
{View} = Views
{Model} = Models
{Collection} = Collections

class Views.GaugeContainer extends View
  init: ->
    @el = new Container()
    @list = []
    @sheet = new SpriteSheet
      images: [Wol.getAsset 'gauges']
      frames: [
        [0,0,57,14] # shield bg
        [0,14,57,14] # armor bg
        [0,28,53,5] # hp bg
        [57,0,51,11] # Shield bar
        [57,14,51,11] # armor bar
        [53,28,51,3] # hp bar
      ]
  add: (id) ->
    gauge = new Gauge @sheet
    gauge.id = id
    @el.addChild gauge.el
    @list.push gauge
    gauge

  getById: (id) ->
    @list.find (gauge) ->
      gauge.id is id

  show: -> @el.visible = true

  hide: -> @el.visible = false

 
class Gauge extends Model
  gaugePositions: [
    {x: 0, y: 0}
    {x: 0, y: -11}
    {x: 0, y: -15}
  ]
  init: (sheet) ->
    @el = new Container()
    @shieldBg = new Bitmap SpriteSheetUtils.extractFrame(sheet ,0)
    @armorBg = new Bitmap SpriteSheetUtils.extractFrame(sheet, 1)
    @healthBg = new Bitmap SpriteSheetUtils.extractFrame(sheet, 2)
    @shieldBar = new Bitmap SpriteSheetUtils.extractFrame(sheet, 3)
    @armorBar = new Bitmap SpriteSheetUtils.extractFrame(sheet, 4)
    @healthBar = new Bitmap SpriteSheetUtils.extractFrame(sheet, 5)

    @health = new Container()
    @health.addChild @healthBg
    @health.addChild @healthBar
    @healthBar.x = 1
    @healthBar.y = 1
    @el.addChild @health

    @armor = new Container()
    @armor.addChild @armorBg
    @armor.addChild @armorBar
    @armorBar.x = 3
    @armorBar.y = 1
    @el.addChild @armor

    @shield = new Container()
    @shield.addChild @shieldBg
    @shield.addChild @shieldBar
    @shieldBar.x = 3
    @shieldBar.y = 1
    @el.addChild @shield

    #
    this

  update: (stats) ->
    {baseShield, baseArmor, baseHealth} = stats
    {shield, armor, health} = stats
    if baseHealth > 0
      @healthBar.scaleX = Math.max 0, health / baseHealth
    if baseArmor?
      if baseArmor > 0
        @armorBar.scaleX = Math.max 0, armor / baseArmor
    if baseShield?
      if baseShield > 0
        @shieldBar.scaleX = Math.max 0 , shield / baseShield
    this

  position: (x, y) ->
    @el.x = x
    @el.y = y
    this
  
  move: (data) ->
    {x, y, speed} = data
    return @position x, y
    Tween.get(@el)
      .to({x: x, y: y}, speed)

  updateElements: (stats) ->
    {baseShield, baseArmor, baseHealth} = stats
    count = 0
    if baseHealth > 0
      @health.x = @gaugePositions[count].x + 2
      @health.y = @gaugePositions[count].y
      count++
    else
      @health.visible = false

    if baseArmor > 0
      @armor.x = @gaugePositions[count].x
      @armor.y = @gaugePositions[count].y
      count++
    else
      @armor.visible = false

    if baseShield > 0
      @shield.x = @gaugePositions[count].x
      @shield.y = @gaugePositions[count].y
      count++
    else
      @shield.visible = false

  hide: ->
    @el.visible = false
