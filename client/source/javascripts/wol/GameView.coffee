#= require wol/Ui
#= require wol/HexTile
#= require wol/Unit
#= require wol/HexLineContainer
#= require wol/Commands

## notes
# if you want to validate tile movement,
# calculate the unit's total AP and compare

@Wol

@after = (ms, cb) -> setTimeout cb, ms

class Wol.Views.GameView extends Wol.Views.View

  init: ->
    return

