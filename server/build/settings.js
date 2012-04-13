if(!Wol) var Wol = {}
Wol.AssetList = [
  {
    name: 'background',
    url: '/images/background.png'
  },{
    name: 'terrain',
    url: '/images/terrain.png'
  },{
    name: 'hex',
    url: '/images/hex.png'
  },{
    name: 'hex_move',
    url: '/images/hex_move.png'
  },{
    name: 'marine',
    url: '/images/marine.png'
  },{
    name: 'hex_act',
    url: '/images/hex_act.png'
  },{
    name: 'hex_act_target',
    url: '/images/hex_act_target.png'
  }
];

Wol.Settings = {
  terrainX: -60,
  terrainY: 150,
  columns: 7,
  rows: 7
};


// =====================================
// Unit Stats
// =====================================
Wol.UnitStats = {};
Wol.UnitStats['lemurian_marine'] = {
  name: 'Lemurian Marine',
  stats: {
    baseHealth: 300,
    baseEnergy: 10,
    baseShield: 0,
    baseArmor: 0,
    baseActions: 6,
    health: 300,
    energy: 5,
    shield: 0,
    armor: 0,
    actions: 4,
    moveRadius: 3,
    charge: 100,
    chargeSpeed: 10
  }
};

// =====================================
// Unit Commands
// =====================================
/**
  command properties
  ------------------
  name <str>
    the name of the command that will be displayed to the client.
  code <str>
    the id of the command that is used for client and server identification.
  cost <int>
    how much it consumes the unit's action points
  type <str>
    the tile coverage of the command
      - 'linear'
      - 'radial'
  radius <int>
    the radius of the tile type coverage
  damage <num>
    a round number base damage
  damageBonus <num>
    a bonus value that is randomized during calculation and added on top of the
    base damage value.
  affinity <str>
    specifies the attack unit.
      - 'physical'  -> normal damage
      - 'technical' -> targets shields and protection
      - 'force' -> increases or decreases bonus damages
/**/
Wol.UnitCommands = {};
Wol.UnitCommands['lemurian_marine'] = [
  {
    name: 'Pulse Rifle Shot',
    code: 'marine_pulse_rifle_shot',
    cost: 7,
    type: 'linear',
    radius: 3,
    affinity: 'physical',
    damage: {
      health: {
        value: 100,
        bonus: 10
      },
      shield: {
        value: 50,
        bonus: 0
      },
      armor: {
        value: 50,
        bonus: 0
      }
    }
  }
];

exports.Wol = Wol;
