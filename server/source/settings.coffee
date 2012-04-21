Wol = {}  unless Wol

Wol.Settings =
  columns: 8
  rows: 8

Wol.UnitStats =
  lemurian_marine:
    name: "Lemurian Marine"
    role: "infantry"
    stats:
      baseHealth: 1300
      baseEnergy: 10
      baseShield: 0
      baseArmor: 0
      baseActions: 4
      health: 300
      energy: 5
      shield: 0
      armor: 0
      actions: 6
      moveRadius: 3
      charge: 100
      chargeSpeed: 10

Wol.UnitCommands =
  lemurian_marine: [
    name: "Pulse Rifle Shot"
    code: "marine_pulse_rifle_shot"
    cost: 1
    type: "linear"
    radius: 8
    affinity: "physical"
    damage:
      health:
        value: 50
        bonus: 10

      shield:
        value: 10
        bonus: 0

      armor:
        value: 10
        bonus: 0
   ]

exports.Wol = Wol
