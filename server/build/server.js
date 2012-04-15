/*
# Node Game Server
# ------------------------------------------------
# Author  : James Florentino
# E-mail  : j@jamesflorentino.com
# Github  : @jamesflorentino
*/
var Collection, EventDispatcher, Hex, HexGrid, MAX_PLAYERS_PER_ROOM, MAX_USERS_PER_ROOM, Model, PORT, PlayerType, Room, ServerData, ServerProtocol, Unit, User, Wol, after, every, io, onConnect, randomId, testRoom,
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

PORT = Number(process.env.PORT || 1337);

MAX_PLAYERS_PER_ROOM = 1;

MAX_USERS_PER_ROOM = 3;

PlayerType = {
  SPECTATOR: 'spectator',
  PLAYER: 'player',
  ARBITER: 'arbiter'
};

io = require('socket.io').listen(PORT);

Wol = require('./settings').Wol;

randomId = function(len) {
  var chars, i, result;
  if (len == null) len = 10;
  chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  result = '';
  while (result.length < len) {
    i = Math.random() * chars.length;
    result += chars.substr(i, 1);
  }
  return result;
};

after = function(ms, cb) {
  return setTimeout(cb, ms);
};

every = function(ms, cb) {
  return setInterval(cb, ms);
};

Array.prototype.last = function() {
  return this[this.length - 1];
};

Array.prototype.first = function() {
  return this[0];
};

Array.prototype.at = function(i) {
  return this[i];
};

Array.prototype.shuffle = function() {
  return this.sort(function(a, b) {
    return Math.round(Math.random() * 10) % 2;
  });
};

Array.prototype.find = function(cb) {
  return (this.filter(cb))[0];
};

Array.prototype.each = function(cb) {
  var child, _i, _len, _results;
  _results = [];
  for (_i = 0, _len = this.length; _i < _len; _i++) {
    child = this[_i];
    _results.push(cb(child));
  }
  return _results;
};

EventDispatcher = (function() {

  function EventDispatcher() {}

  EventDispatcher.prototype.bind = function(name, callback) {
    var _base;
    this.e || (this.e = {});
    (_base = this.e)[name] || (_base[name] = []);
    this.e[name].push(callback);
    return this;
  };

  EventDispatcher.prototype.unbind = function(name, callback) {
    var index;
    if (!this.e) return;
    if (arguments.length === 0) {
      this.e = {};
      return this;
    }
    if (!this.e[name]) return this;
    if (!callback) {
      delete this.e[name];
      return this;
    }
    index = this.e[name].indexOf(callback);
    this.e[name].splice(index, 1);
    return this;
  };

  EventDispatcher.prototype.trigger = function(name, data) {
    if (!this.e) return this;
    if (!this.e[name]) return this;
    this.e[name].each(function(event) {
      if (event != null) return event(data);
    });
    return this;
  };

  return EventDispatcher;

})();

Model = (function(_super) {

  __extends(Model, _super);

  Model.prototype.id = randomId();

  Model.prototype.attributes = [];

  function Model(attributes) {
    this.attributes = {};
    this.id = randomId();
    this.set(attributes);
    this.initialize(attributes);
    return;
  }

  Model.prototype.initialize = function(options) {};

  Model.prototype.set = function(props) {
    var key;
    for (key in props) {
      this.attributes[key] = props[key];
    }
    return this;
  };

  Model.prototype.get = function(propertyName) {
    return this.attributes[propertyName];
  };

  return Model;

})(EventDispatcher);

Collection = (function(_super) {

  __extends(Collection, _super);

  function Collection() {
    Collection.__super__.constructor.apply(this, arguments);
  }

  Collection.prototype.collection = [];

  Collection.prototype.initialize = function() {
    return this.collection = [];
  };

  Collection.prototype.add = function(data) {
    var _this = this;
    if (data instanceof Array) {
      data.each(function(item) {
        if (item instanceof Model) {
          return _this.collection.push(item);
        } else {
          return _this.collection.push(new Model(item));
        }
      });
      return;
    }
    return this.collection.push(data);
  };

  Collection.prototype.removeById = function(id) {
    var model;
    model = this.collection.filter(function(item) {
      return item.id === id;
    });
    return this.collection.splice(this.collection.indexOf(model), 1);
  };

  Collection.prototype.remove = function(model) {
    return this.collection.splice(this.collection.indexOf(model));
  };

  Collection.prototype.find = function(cb) {
    return (this.collection.filter(cb))[0];
  };

  Collection.prototype.getAttributes = function() {
    return this.collection.map(function(model) {
      return model.attributes;
    });
  };

  return Collection;

})(Model);

User = (function(_super) {

  __extends(User, _super);

  function User() {
    User.__super__.constructor.apply(this, arguments);
  }

  User.prototype.initialize = function() {
    console.log("User Event: " + (this.get('name')) + " <" + this.id + "> enters a game");
  };

  User.prototype.announce = function(eventName, message) {
    this.get('socket').emit(eventName, message);
    return this;
  };

  return User;

})(Model);

Room = (function(_super) {

  __extends(Room, _super);

  function Room() {
    Room.__super__.constructor.apply(this, arguments);
  }

  Room.prototype.users = [];

  Room.prototype.units = [];

  Room.prototype.ready = false;

  Room.prototype.totalUsers = 0;

  Room.prototype.grid = void 0;

  Room.prototype.initialize = function() {
    this.users = [];
    this.units = [];
    this.ready = false;
    this.totalUsers = 0;
    this.grid = new HexGrid();
    this.grid.generate(8, 8);
    this.setEvents();
  };

  Room.prototype.addUser = function(user) {
    this.users.push(user);
    this.totalUsers = this.users.length;
    return this;
  };

  Room.prototype.removeUser = function(user) {
    this.users.splice(this.users.indexOf(user));
    this.totalUsers = this.users.length;
    return this;
  };

  Room.prototype.getUserById = function(userId) {
    var user;
    user = this.users.filter(function(user) {
      return user.id === userId;
    });
    return user[0];
  };

  Room.prototype.getUnitByTileId = function(tileId) {
    return this.units.find(function(unit) {
      return tileId === ("" + (unit.get('tileX')) + "_" + (unit.get('tileY')));
    });
  };

  Room.prototype.announce = function(eventName, data) {
    console.log("Room Event: " + eventName);
    console.log(data);
    this.users.each(function(user) {
      return user.announce(eventName, data);
    });
    return this;
  };

  Room.prototype.addUnit = function(unitCode, userId) {
    var unit;
    unit = new Unit(unitCode);
    unit.set({
      userId: userId,
      roomId: this.id
    });
    unit.stats.set({
      charge: 0
    });
    this.units.push(unit);
    return unit;
  };

  Room.prototype.getUnitById = function(unitId) {
    var unit;
    unit = this.units.filter(function(unit) {
      return unit.id === unitId;
    });
    return unit[0];
  };

  Room.prototype.startGame = function() {
    return this;
  };

  Room.prototype.endGame = function() {
    var unit, userId;
    unit = ((function() {
      var _i, _len, _ref, _results;
      _ref = this.units;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        unit = _ref[_i];
        if (unit.dead === false) _results.push(unit);
      }
      return _results;
    }).call(this)).first();
    userId = unit.get('userId');
    return this.trigger('endGame', {
      userId: userId
    });
  };

  Room.prototype.setEvents = function() {};

  Room.prototype.getNextTurn = function() {
    var activeUnit, intervalId, roomId, roomName, tickSpeed, units,
      _this = this;
    roomId = this.id;
    roomName = this.get('name');
    units = this.units;
    activeUnit = void 0;
    tickSpeed = 100;
    console.log('\n', 'calculating next turn...');
    return intervalId = every(tickSpeed, function() {
      var highestCharge;
      highestCharge = 0;
      units.each(function(unit) {
        var charge, chargeSpeed;
        if (unit.getStat('health') === 0) return;
        chargeSpeed = unit.getStat('chargeSpeed');
        charge = unit.getStat('charge');
        charge += chargeSpeed + Math.random() * 2;
        unit.stats.set({
          charge: charge
        });
        if (charge > highestCharge) highestCharge = charge;
        if (charge > 100) activeUnit = unit;
        console.log("charging unit " + unit.id + "..." + charge);
      });
      if (highestCharge === 0) {
        clearInterval(intervalId);
        return;
      }
      if (activeUnit != null) {
        clearInterval(intervalId);
        activeUnit.stats.set({
          charge: 0
        });
        _this.set({
          activeUnit: activeUnit
        });
        _this.trigger('unitTurn', {
          unit: activeUnit
        });
        console.log("unit selected", activeUnit);
      }
    });
  };

  Room.prototype.getLivingUnits = function() {
    var unit, what, _i, _len, _ref;
    _ref = this.units;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      unit = _ref[_i];
      if (unit.dead === false) what = unit;
    }
    what = this.units.filter(function(unit) {
      return unit.dead === false;
    });
    return what;
  };

  Room.prototype.getPlayers = function() {
    return this.users.map(function(user) {
      return user.get('playerType') === PlayerType.PLAYER;
    });
  };

  Room.prototype.reset = function() {
    this.units = [];
    console.log("deleting users.. from room " + (this.get('name')) + " <" + this.id + ">");
    this.users.each(function(user) {
      var socket;
      socket = user.get('socket');
      socket.disconnect();
      return console.log("deleted " + (user.get('name')) + " <" + user.id + ">...");
    });
    this.set({
      ready: false
    });
    this.users = [];
    return this.totalUsers = this.users.length;
  };

  return Room;

})(Model);

Unit = (function(_super) {

  __extends(Unit, _super);

  function Unit(unitCode) {
    var unitCommands, unitStats;
    Unit.__super__.constructor.call(this);
    unitStats = Wol.UnitStats[unitCode];
    this.set({
      acted: false,
      moved: false,
      code: unitCode,
      name: unitStats.name,
      role: unitStats.role
    });
    this.stats = new Model();
    this.stats.set(unitStats.stats);
    unitCommands = Wol.UnitCommands[unitCode];
    this.commands = new Collection();
    this.commands.add(unitCommands);
    this.dead = false;
  }

  Unit.prototype.receiveDamageData = function(damageData) {
    var stats;
    stats = {
      health: this.getStat('health'),
      shield: this.getStat('shield'),
      armor: this.getStat('armor')
    };
    stats.health -= damageData.health;
    stats.shield -= damageData.shield;
    stats.armor -= damageData.armor;
    stats.health = Math.max(0, stats.health);
    stats.shield = Math.max(0, stats.shield);
    stats.armor = Math.max(0, stats.armor);
    this.stats.set({
      health: stats.health,
      shield: stats.shield,
      armor: stats.armor
    });
    return {
      health: this.getStat('health'),
      shield: this.getStat('shield'),
      armor: this.getStat('armor')
    };
  };

  Unit.prototype.filterDamageData = function(damageData) {
    var damage;
    damage = {
      health: damageData.health,
      shield: damageData.shield,
      armor: damageData.armor
    };
    return {
      health: damage.health,
      shield: damage.shield,
      armor: damage.armor
    };
  };

  Unit.prototype.getDamageData = function(commandCode) {
    var armor, command, damage, health, shield;
    command = this.getCommandByCode(commandCode);
    damage = command.get('damage');
    health = damage.health.value;
    shield = damage.shield.value;
    armor = damage.armor.value;
    health += Math.round(Math.random() * damage.health.bonus);
    shield += Math.round(Math.random() * damage.shield.bonus);
    armor += Math.round(Math.random() * damage.armor.bonus);
    return {
      health: health,
      shield: shield,
      armor: armor
    };
  };

  Unit.prototype.setStat = function(data) {
    return this.stats.set(data);
  };

  Unit.prototype.getStat = function(statName) {
    return this.stats.get(statName);
  };

  Unit.prototype.getCommandByCode = function(commandCode) {
    return this.commands.find(function(command) {
      return command.get('code') === commandCode;
    });
  };

  Unit.prototype.move = function(hex) {
    return this.set({
      tileX: hex.get('tileX'),
      tileY: hex.get('tileY')
    });
  };

  return Unit;

})(Model);

Hex = (function(_super) {

  __extends(Hex, _super);

  function Hex() {
    Hex.__super__.constructor.apply(this, arguments);
  }

  Hex.prototype.initialize = function() {
    return this.set({
      cost: 1
    });
  };

  return Hex;

})(Model);

HexGrid = (function(_super) {

  __extends(HexGrid, _super);

  function HexGrid() {
    HexGrid.__super__.constructor.apply(this, arguments);
  }

  HexGrid.prototype.generate = function(cols, rows) {
    var tileX, tileY, _results;
    tileY = 0;
    _results = [];
    while (tileY < rows) {
      tileX = 0;
      while (tileX < cols) {
        this.add(new Hex({
          tileX: tileX,
          tileY: tileY
        }));
        tileX++;
      }
      _results.push(tileY++);
    }
    return _results;
  };

  HexGrid.prototype.convertPoints = function(points) {
    var _this = this;
    if (!points) return;
    if (!points.length) return;
    return points.map(function(point) {
      return _this.find(function(t) {
        return t.get('tileX') === point.tileX && t.get('tileY') === point.tileY;
      });
    });
  };

  return HexGrid;

})(Collection);

ServerData = {
  rooms: [],
  users: []
};

ServerProtocol = {
  createRoom: function(roomName) {
    var room, roomId;
    room = new Room({
      name: roomName
    });
    roomId = room.id;
    room.bind('endGame', function(event) {
      var message, userId;
      userId = event.userId, message = event.message;
      return room.announce('endGame', {
        userId: userId,
        message: message
      });
    });
    room.bind('unitTurn', function(event) {
      var message, unit, unitId, user, userId;
      unit = event.unit;
      unit.set({
        moved: false,
        acted: false
      });
      unit.stats.set({
        actions: unit.stats.get('baseActions')
      });
      unitId = unit.id;
      userId = unit.get('userId');
      user = room.getUserById(userId);
      message = "" + roomName + ": " + (user.get('name')) + "'s " + (unit.get('name')) + " is taking its turn.";
      room.set({
        activeUnit: unit
      });
      room.announce('unitTurn', {
        unitId: unitId,
        message: message,
        stats: {
          actions: unit.getStat('actions')
        }
      });
      return console.log(message);
    });
    ServerData.rooms.push(room);
    return room;
  },
  getRoomById: function(roomId) {
    var room;
    room = ServerData.rooms.filter(function(room) {
      return room.id === roomId;
    });
    return room[0];
  },
  joinRoom: function(user, room, raceName) {
    var playerType, players, roomId, roomName, socket, totalUsers, userId, userName;
    if (room === void 0) return;
    userId = user.id;
    userName = user.get('name');
    roomId = room.id;
    roomName = room.get('name');
    socket = user.get('socket');
    playerType = PlayerType.PLAYER;
    user.set({
      raceName: raceName
    });
    if (room.totalUsers >= MAX_USERS_PER_ROOM) {
      user.announce('roomError', {
        message: 'Room is already full'
      });
      socket.disconnect();
      return;
    }
    room.addUser(user);
    totalUsers = room.totalUsers;
    if (totalUsers > MAX_PLAYERS_PER_ROOM) playerType = PlayerType.SPECTATOR;
    user.set({
      playerType: playerType
    });
    if (user.get('playerType') === PlayerType.PLAYER) {
      players = room.getPlayers();
      user.set({
        playerNumber: players.length
      });
      ServerProtocol.assignEvents(userId, roomId);
    }
    socket.on('reconnect', function() {
      return console.log("" + userName + " reconnected to " + roomName);
    });
    socket.on('disconnect', function() {
      console.log("" + userName + " disconnected from " + roomName);
      room.removeUser(user);
      if (room.getPlayers().length < MAX_PLAYERS_PER_ROOM) {
        room.announce('endGame', {
          message: "Player " + userName + " has left. The game has ended."
        });
        console.log("Deleting room " + roomName + " <" + roomId + ">");
        room.reset();
        return;
      }
      return room.announce('removeUser', {
        roomId: roomId,
        userId: userId,
        userName: userName,
        message: "" + playerType + " " + userName + " has left the game."
      });
    });
    user.announce('joinRoom', {
      roomId: roomId,
      roomName: roomName,
      message: "Hi " + userName + ", you have joined " + roomName + " <" + roomId + ">"
    });
    room.users.each(function(u) {
      if (u === user) return;
      return user.announce('addUser', {
        userId: u.id,
        userName: u.get('name'),
        playerNumber: u.get('playerNumber'),
        playerType: u.get('playerType'),
        raceName: u.get('raceName'),
        message: "" + playerType + " " + userName + " has joined the game."
      });
    });
    room.announce('addUser', {
      userId: userId,
      userName: userName,
      playerNumber: user.get('playerNumber'),
      playerType: user.get('playerType'),
      raceName: user.get('raceName'),
      message: "" + playerType + " " + userName + " has joined the game."
    });
    if (totalUsers >= MAX_PLAYERS_PER_ROOM) {
      if (room.get('ready') === true) {
        ServerProtocol.updateClient(user, room);
        return;
      }
      room.set({
        ready: true
      });
      ServerProtocol.startGame(roomId);
    }
    return room;
  },
  updateClient: function(user, room) {
    var roomId, socket, userId;
    userId = user.id;
    socket = user.get('socket');
    roomId = room.id;
    user.announce('startGame', {
      message: 'You are late'
    });
    room.units.each(function(unit) {
      user.announce('addUnit', {
        userId: unit.get('userId'),
        unitId: unit.id,
        tileX: unit.get('tileX'),
        tileY: unit.get('tileY'),
        unitCode: unit.get('code'),
        unitName: unit.get('name'),
        unitRole: unit.get('role'),
        message: "" + (user.get('name')) + "'s " + (unit.get('name')) + " has been deployed to " + (room.get('name')) + ".",
        face: unit.get('face'),
        unitStats: unit.stats.attributes,
        unitCommands: unit.commands.getAttributes()
      });
    });
  },
  startGame: function(roomId) {
    var players, room, unit, unitB;
    room = ServerProtocol.getRoomById(roomId);
    room.announce('startGame', {
      message: 'Game has started'
    });
    players = room.users.filter(function(u) {
      return u.get('playerType') === PlayerType.PLAYER;
    });
    unit = ServerProtocol.addUnit({
      userId: players.first().id,
      roomId: roomId,
      unitCode: 'lemurian_marine',
      tileX: 0,
      tileY: 2
    });
    unitB = ServerProtocol.addUnit({
      userId: players.last().id,
      roomId: roomId,
      unitCode: 'lemurian_marine',
      tileX: 6,
      tileY: 3,
      face: 'left'
    });
    room.getNextTurn();
  },
  addUnit: function(data) {
    var face, room, roomId, tileX, tileY, unit, unitCode, user, userId;
    unitCode = data.unitCode, roomId = data.roomId, userId = data.userId, tileX = data.tileX, tileY = data.tileY, face = data.face;
    room = ServerProtocol.getRoomById(roomId);
    user = room.getUserById(userId);
    unit = room.addUnit(unitCode, userId);
    unit.set({
      tileX: tileX,
      tileY: tileY,
      face: face
    });
    room.announce('addUnit', {
      userId: user.id,
      unitId: unit.id,
      tileX: tileX,
      tileY: tileY,
      unitCode: unit.get('code'),
      unitName: unit.get('name'),
      unitRole: unit.get('role'),
      message: "" + (user.get('name')) + "'s " + (unit.get('name')) + " has been deployed to " + (room.get('name')) + ".",
      face: face,
      unitStats: unit.stats.attributes,
      unitCommands: unit.commands.getAttributes()
    });
    return unit;
  },
  moveUnit: function(data) {
    var point, points, room, roomId, tileX, tileY, unit, unitId, unitName, user, userId, userName;
    roomId = data.roomId, unitId = data.unitId, points = data.points;
    room = ServerProtocol.getRoomById(roomId);
    unit = room.getUnitById(unitId);
    userId = unit.get('userId');
    user = room.getUserById(userId);
    point = points.last();
    unit.set({
      tileX: point.tileX,
      tileY: point.tileY
    });
    userName = user.get('name');
    unitName = unit.get('name');
    tileX = points[points.length - 1].tileX;
    tileY = points[points.length - 1].tileY;
    return after(1000, function() {
      return room.announce('moveUnit', {
        unitId: unitId,
        points: points,
        message: "" + (user.get('name')) + "'s " + (unit.get('name')) + " is moving to hex(" + tileX + ", " + tileY + ")"
      });
    });
  },
  assignEvents: function(userId, roomId) {
    var room, socket, user;
    room = ServerProtocol.getRoomById(roomId);
    user = room.getUserById(userId);
    socket = user.get('socket');
    socket.on('actUnit', function(data) {
      var command, commandCode, damageData, points, targets, tiles, unit, unitId;
      unitId = data.unitId, points = data.points, commandCode = data.commandCode;
      if (!unitId) return;
      if (!commandCode) return;
      if (!points) return;
      if (points.length === 0) return;
      unit = room.getUnitById(unitId);
      if (!unit) return console.log('invalid unitId');
      if (room.get('activeUnit') !== unit) {
        return console.log("unit is not hte active unit");
      }
      tiles = room.grid.convertPoints(points);
      if (tiles.length === 0) return console.log('invalid points', points);
      command = unit.getCommandByCode(commandCode);
      if (unit.getStat('actions') - command.get('cost') < 0) return;
      damageData = unit.getDamageData(commandCode);
      targets = [];
      unit.setStat({
        actions: unit.getStat('actions') - command.get('cost')
      });
      points.each(function(point) {
        var targetUnit, targetUnitStats, totalDamageData;
        targetUnit = room.units.find(function(u) {
          return u.get('tileX') === point.tileX && u.get('tileY') === point.tileY;
        });
        if (!targetUnit) return;
        if (targetUnit.dead === true) return;
        totalDamageData = targetUnit.filterDamageData(damageData);
        targetUnitStats = targetUnit.receiveDamageData(totalDamageData);
        targets.push({
          unitId: targetUnit.id,
          damage: totalDamageData,
          stats: targetUnitStats
        });
        if (targetUnit.getStat('health') === 0) return targetUnit.dead = true;
      });
      if (targets.length === 0) return;
      after(1000, function() {
        return room.announce('actUnit', {
          unitId: unitId,
          targets: targets,
          commandCode: commandCode
        });
      });
      return this;
    });
    socket.on('moveUnit', function(data) {
      var conflictedTiles, face, points, tiles, totalActions, unit, unitId;
      if (!data.unitId || !data.points) {
        return console.log("invalid unit and points", data);
      }
      face = data.face, unitId = data.unitId, points = data.points;
      unit = room.getUnitById(unitId);
      if (!unit) return console.log("invalid unitId", unitId);
      if (room.get('activeUnit') !== unit) {
        return console.log("unit is not hte active unit");
      }
      if (unit.get('userId') !== userId) {
        return console.log("user isn't the active user");
      }
      tiles = room.grid.convertPoints(points);
      if (tiles.length === 0) {
        room.announce('unitTurn', {
          unitId: unit.id,
          stats: {
            actions: unit.getStat('actions')
          },
          message: "<Invalid tiles> " + (user.get('name')) + "'s " + (unit.get('name')) + " is continuing its turn."
        });
        return;
      }
      totalActions = 0;
      unit.set({
        face: face
      });
      conflictedTiles = [];
      tiles.each(function(tile) {
        var occupiedUnit, tileId;
        tileId = "" + (tile.get('tileX')) + "_" + (tile.get('tileY'));
        totalActions += tile.get('cost');
        occupiedUnit = room.getUnitByTileId(tileId);
        if (occupiedUnit != null) {
          if (occupiedUnit.dead !== true) conflictedTiles.push(tile);
        }
      });
      if (unit.getStat('actions') < totalActions) {
        return console.log("cost of movement is < actions", unitId);
      }
      if (conflictedTiles.length > 0) {
        return console.log("one of the tiles is occupied");
      }
      unit.setStat({
        actions: unit.getStat('actions') - totalActions
      });
      unit.move(tiles.last());
      ServerProtocol.moveUnit({
        unitId: unitId,
        roomId: roomId,
        points: points
      });
    });
    socket.on('moveUnitEnd', function(data) {
      var deadUnit, tileX, tileY, type, unit, unitId;
      unitId = data.unitId, type = data.type;
      unit = room.getUnitById(unitId);
      if (userId !== unit.get('userId')) return;
      if (unit === void 0) return;
      if (unit !== room.get('activeUnit')) return;
      tileX = unit.get('tileX');
      tileY = unit.get('tileY');
      deadUnit = room.units.find(function(u) {
        return (u !== unit) && (u.get('tileX') === tileX && u.get('tileY') === tileY) && (u.dead === true);
      });
      if (deadUnit != null) {
        room.announce('removeUnit', {
          unitId: deadUnit.id
        });
      }
      if (room.getLivingUnits().length <= 1) {
        room.endGame();
        return;
      }
      if (unit.getStat('actions') > 0) {
        room.announce('unitTurn', {
          unitId: unit.id,
          stats: {
            actions: unit.getStat('actions')
          },
          message: "" + (user.get('name')) + "'s " + (unit.get('name')) + " is continuing its turn."
        });
      } else {
        room.getNextTurn();
      }
    });
    socket.on('skipTurn', function(data) {
      var unit, unitId;
      unitId = data.unitId;
      unit = room.getUnitById(unitId);
      if (unit === void 0) return;
      if (userId !== unit.get('userId')) return;
      if (unit !== room.get('activeUnit')) return;
      return room.getNextTurn();
    });
  }
};

testRoom = ServerProtocol.createRoom('Asgard');

onConnect = function(socket) {
  var user;
  user = null;
  socket.on('setUserName', function(data) {
    var raceName, userName;
    if (user != null) return;
    userName = data.userName;
    user = new User({
      socket: socket,
      name: userName
    });
    user.announce('setUserName', {
      userId: user.id,
      userName: user.get('name')
    });
    raceName = 'lemurian';
    ServerProtocol.joinRoom(user, testRoom, raceName);
  });
  socket.on('joinRoom', function(roomId, options) {
    var raceName, room;
    if (options != null) raceName = options.raceName;
    raceName || (raceName = 'lemurian');
    room = ServerProtocol.getRoomById(roomId);
    ServerProtocol.joinRoom(user, room);
  });
};

io.set('brower client minification', true);

io.set('log level', 1);

io.configure(function() {
  return io.set('transports', ['websocket']);
});

io.sockets.on('connection', onConnect);
