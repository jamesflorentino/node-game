@Wol

class Wol.Views.UnitContainer extends Wol.Views.View
  init: ->
    @el = new Container()
    @units = []
    return
  
  createUnitByCode: (unitCode, alternateColor = false) ->
    switch unitCode
      when Wol.UnitNames.MARINE then new Wol.Views.Marine alternateColor: alternateColor

  addUnit: (unit) ->
    @el.addChild unit.el
    @units.push unit
    unit
  
  getUnitById: (unitId) ->
    units = (unit for unit in @units when unit.get('unitId') is unitId)
    units[0]

  getUnitByTileId: (tileId) ->
    units = (unit for unit in @units when "#{unit.get('tileX')}_#{unit.get('tileY')}" is tileId)
    units[0]

  getUnitByPoint: (point) ->
    units = (unit for unit in @units when unit.get('tileX') is point.x and unit.get('tileY') is point.y)
    units[0]




