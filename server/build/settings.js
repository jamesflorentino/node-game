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
    baseHealth: 100,
    baseEnergy: 10,
    health: 80,
    energy: 5,
    baseActions: 4,
    actions: 4,
    moveRadius: 3,
    charge: 100,
    chargeSpeed: 10
  }
};

// =====================================
// Unit Commands
// =====================================
Wol.UnitCommands = {};
Wol.UnitCommands['lemurian_marine'] = [
  {
    name: 'Pulse Rifle Shot',
    code: 'marine_pulse_rifle_shot',
    cost: 1,
    type: 'linear',
    radius: 3
  },{
    name: 'Frag Grenade',
    code: 'marine_frag_grenade',
    cost: 5,
    type: 'radial',
    radius: 5
  }
]


exports.Wol = Wol
