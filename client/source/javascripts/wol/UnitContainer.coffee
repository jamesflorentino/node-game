@Wol

class Wol.Views.UnitContainer extends Wol.Views.View
  init: ->
    @el = new Container()
    @units = []
    return
  
  createUnitByCode: (unitCode) ->
    switch unitCode
      when Wol.UnitNames.MARINE then new Wol.Views.Marine()

  addUnit: (unit) ->
    @el.addChild unit.el
    @units.push unit
    this
  
  getUnitById: (unitId) ->
    result = @units.filter (unit) -> unit.get('unitId') is unitId
    result[0]

  getUnitByTileId: (tileId) ->
    @units.find (unit) ->
      tileId is "#{unit.get('tileX')}_#{unit.get('tileY')}"
