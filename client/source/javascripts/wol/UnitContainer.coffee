@Wol

class Wol.Views.UnitContainer extends Wol.Views.View
	init: ->
		@el = new Container()
		@units = []
		return
	
	createUnitByCode: (unitCode) ->
		unit = null
		switch unitCode
			when Wol.UnitNames.MARINE
				unit = new Wol.Views.Marine()
		unit

	addUnit: (unit) ->
		@el.addChild unit.el
		@units.push unit
		this
	
	getUnitById: (unitId) ->
		result = @units.filter (unit) -> unit.get('unitId') is unitId
		result[0]

