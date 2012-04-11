Wol.AssetList = [
  {
    name: 'background',
    url: '/images/background_mars.png'
  },{
    name: 'terrain',
    url: '/images/terrain_mars_lighter.png'
  },{
    name: 'hex',
    url: '/images/hex.png'
  },{
    name: 'hex_bg',
    url: '/images/hex_bg.png'
  },{
    name: 'hex_move',
    url: '/images/hex_move.png'
  },{
    name: 'marine',
    url: '/images/marine.png'
  },{
    name: 'marine_alternate',
    url: '/images/marine_alternate.png'
  },{
    name: 'hex_act',
    url: '/images/hex_act.png'
  },{
    name: 'hex_act_target',
    url: '/images/hex_act_target.png'
  },{
    name: 'damage',
    url: '/images/damage_numbers.png'
  },{
    name: 'gauges',
    url: '/images/sprite_gauges.png'
  }
];

Wol.Settings = {
  gameWidth: 960,
  gameHeight: 640,
  terrainX: 0,
  terrainY: 150,
  columns: 7,
  rows: 6
};

Wol.UnitNames = {
  MARINE: 'lemurian_marine'
};

Wol.UnitStats = {};
Wol.UnitStats[Wol.UnitNames.MARINE] = {
  id: ''.randomId(10),
  name: 'Lemurian Marine',
  stats: {
    baseHealth: 100,
    baseEnergy: 10,
    health: 80,
    energy: 5,
    actions: 4,
    moveRadius: 3,
    charge: 100
  }
};
