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

MAX_USERS_PER_ROOM = 2;

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
    this.e[name].forEach(function(event) {
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

  Collection.prototype.add = function(model) {
    return this.collection.push(model);
  };

  Collection.prototype.remove = function(model) {
    return this.collection.splice(this.collection.indexOf(model));
  };

  Collection.prototype.find = function(cb) {
    return (this.collection.filter(cb))[0];
  };

  return Collection;

})(Model);

User = (function(_super) {

  __extends(User, _super);

  function User() {
    User.__super__.constructor.apply(this, arguments);
  }

  User.prototype.initialize = function() {
    console.log("====================");
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
    return this;
  };

  Room.prototype.getUserById = function(userId) {
    var user;
    user = this.users.filter(function(user) {
      return user.id === userId;
    });
    return user[0];
  };

  Room.prototype.announce = function(eventName, data) {
    console.log("====================");
    console.log("Room Event: " + eventName);
    console.log(data);
    this.users.forEach(function(user) {
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
      units.forEach(function(unit) {
        var charge, chargeSpeed;
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

  Room.prototype.reset = function() {
    this.users = [];
    return this.units = [];
  };

  return Room;

})(Model);

Unit = (function(_super) {

  __extends(Unit, _super);

  function Unit(unitCode) {
    var unitStats;
    Unit.__super__.constructor.call(this);
    unitStats = Wol.UnitStats[unitCode];
    this.set({
      acted: false,
      moved: false,
      code: unitCode,
      name: unitStats.name
    });
    this.stats = new Model();
    this.stats.set(unitStats.stats);
  }

  Unit.prototype.getStat = function(statName) {
    return this.stats.get(statName);
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
        message: message
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
  joinRoom: function(user, room) {
    var playerType, roomId, roomName, socket, totalUsers, userId, userName;
    if (room === void 0) return;
    userId = user.id;
    userName = user.get('name');
    roomId = room.id;
    roomName = room.get('name');
    socket = user.get('socket');
    playerType = PlayerType.PLAYER;
    if (room.totalUsers > MAX_USERS_PER_ROOM) {
      user.announce('roomError', {
        message: 'Room is already full'
      });
      return;
    }
    room.addUser(user);
    totalUsers = room.totalUsers;
    if (totalUsers > MAX_PLAYERS_PER_ROOM) playerType = PlayerType.SPECTATOR;
    user.set({
      playerType: playerType
    });
    if (user.get('playerType') === PlayerType.PLAYER) {
      ServerProtocol.assignEvents(userId, roomId);
    }
    socket.on('disconnect', function() {
      room.removeUser(user);
      if (room.users.length === 0) {
        room.reset();
        return;
      }
      room.announce('removeUser', {
        roomId: roomId,
        userId: userId,
        userName: userName,
        message: "" + playerType + " " + userName + " has left the game."
      });
      return console.log("" + userName + " left " + roomName);
    });
    user.announce('joinRoom', {
      roomId: roomId,
      roomName: roomName,
      message: "Hi " + userName + ", you have joined " + roomName + " <" + roomId + ">"
    });
    room.announce('addUser', {
      userId: userId,
      userName: userName,
      message: "" + playerType + " " + userName + " has joined the game."
    });
    if (totalUsers >= MAX_PLAYERS_PER_ROOM) ServerProtocol.startGame(roomId);
    return room;
  },
  startGame: function(roomId) {
    var room, unit, unitB;
    room = ServerProtocol.getRoomById(roomId);
    unit = ServerProtocol.addUnit({
      userId: room.users[0].id,
      roomId: roomId,
      unitCode: 'lemurian_marine',
      tileX: 3,
      tileY: 3
    });
    unitB = ServerProtocol.addUnit({
      userId: room.users.last().id,
      roomId: roomId,
      unitCode: 'lemurian_marine',
      tileX: 4,
      tileY: 3,
      face: 'left'
    });
    ServerProtocol.nextUnitTurn(roomId);
  },
  addUnit: function(data) {
    var face, room, roomId, tileX, tileY, unit, unitCode, user, userId;
    unitCode = data.unitCode, roomId = data.roomId, userId = data.userId, tileX = data.tileX, tileY = data.tileY, face = data.face;
    room = ServerProtocol.getRoomById(roomId);
    user = room.getUserById(userId);
    unit = room.addUnit(unitCode, userId);
    unit.set({
      tileX: tileX,
      tileY: tileY
    });
    room.announce('addUnit', {
      userId: user.id,
      unitId: unit.id,
      tileX: tileX,
      tileY: tileY,
      unitCode: unit.get('code'),
      unitName: unit.get('name'),
      message: "" + (user.get('name')) + "'s " + (unit.get('name')) + " has been deployed to " + (room.get('name')) + ".",
      face: face,
      unitStats: unit.stats.attributes
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
      tileY: point.tileY,
      moved: true
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
  nextUnitTurn: function(roomId) {
    var room;
    room = ServerProtocol.getRoomById(roomId);
    return room.getNextTurn();
  },
  assignEvents: function(userId, roomId) {
    var room, socket, user,
      _this = this;
    room = ServerProtocol.getRoomById(roomId);
    user = room.getUserById(userId);
    socket = user.get('socket');
    socket.on('moveUnit', function(data) {
      var conflictedTiles, moveCost, occupiedTiles, points, tiles, unit, unitAction, unitId;
      if (!data.unitId || !data.points) {
        return console.log("invalid unit and points", data);
      }
      unitId = data.unitId, points = data.points;
      unit = room.getUnitById(unitId);
      if (!unit) return console.log("invalid unitId", unitId);
      if (room.get('activeUnit') !== unit) {
        return console.log("unit is not hte active unit");
      }
      if (unit.get('userId') !== userId) {
        return console.log("user isn't the active user");
      }
      tiles = room.grid.convertPoints(points);
      if (tiles.length === 0) return console.log("invalid points", points);
      unitAction = unit.stats.get('actions');
      moveCost = 0;
      occupiedTiles = room.units.map(function(u) {
        return "" + (u.get('tileX')) + "_" + (u.get('tileY'));
      });
      conflictedTiles = [];
      tiles.forEach(function(tile) {
        var tileId;
        tileId = "" + (tile.get('tileX')) + "_" + (tile.get('tileY'));
        moveCost += tile.get('cost');
        if (occupiedTiles.indexOf(tileId) > -1) conflictedTiles.push(tile);
      });
      if (unitAction < moveCost) {
        return console.log("cost of movement is < actions", unitId);
      }
      if (conflictedTiles.length > 0) {
        return console.log("one of the tiles is occupied");
      }
      unit.stats.set({
        actions: unitAction - moveCost
      });
      unit.move(tiles.last());
      ServerProtocol.moveUnit({
        unitId: unitId,
        roomId: roomId,
        points: points
      });
    });
    socket.on('moveUnitEnd', function(data) {
      var type, unit, unitId;
      unitId = data.unitId, type = data.type;
      unit = room.getUnitById(unitId);
      if (unit === void 0) return;
      if (userId !== unit.get('userId')) return;
      return ServerProtocol.nextUnitTurn(roomId);
      /*
            user.set readyState: true
            usersReady = room.users.filter (u) -> u.get 'readyState'
            return if usersReady.length < MAX_PLAYERS_PER_ROOM
            usersReady.forEach (u) -> user.set readyState: false
            activeUnit = room.get 'activeUnit'
            return if !activeUnit
      */
    });
    socket.on('skipTurn', function(data) {
      var unit, unitId;
      unitId = data.unitId;
      unit = room.getUnitById(unitId);
      if (unit !== room.get('activeUnit')) return;
      return ServerProtocol.nextUnitTurn(roomId);
    });
  }
};

testRoom = ServerProtocol.createRoom('Asgard');

onConnect = function(socket) {
  var user;
  user = null;
  socket.on('setUserName', function(data) {
    var userName;
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
    ServerProtocol.joinRoom(user, testRoom);
  });
  socket.on('joinRoom', function(roomId) {
    var room;
    room = ServerProtocol.getRoomById(roomId);
    ServerProtocol.joinRoom(user, room);
  });
};

io.set('brower client minification', true);

io.set('log level', 1);

/*
io.configure ->
  io.set 'transports', ['xhr-polling']
  io.set 'polling duration', 10
*/

io.sockets.on('connection', onConnect);
