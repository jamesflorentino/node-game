/*
# Node Game Server
# ------------------------------------------------
# Author	: James Florentino
# E-mail	: j@jamesflorentino.com
# Github	: @jamesflorentino
*/
var MAX_PLAYERS_PER_ROOM, MAX_USERS_PER_ROOM, Model, PORT, PlayerType, Room, ServerData, ServerProtocol, Unit, User, Wol, io, onConnect, randomId, testRoom, _,
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

PORT = Number(process.env.PORT || 1337);

MAX_PLAYERS_PER_ROOM = 1;

MAX_USERS_PER_ROOM = 3;

PlayerType = {
  SPECTATOR: 'spectator',
  PLAYER: 'player'
};

io = require('socket.io').listen(PORT);

_ = require('./underscore');

Wol = require('./settings').Wol;

randomId = function(len) {
  var chars, id, index;
  if (len == null) len = 10;
  chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  id = '';
  while (id.length < len) {
    index = Math.random() * chars.length;
    id += chars.substr(index, 1);
  }
  return id;
};

Array.prototype.last = this[this.length - 1];

Model = (function() {

  Model.prototype.id = randomId();

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

})();

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

  Room.prototype.initialize = function() {
    this.users = [];
    this.units = [];
    this.ready = false;
    this.totalUsers = 0;
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
    this.units.push(unit);
    return unit;
  };

  Room.prototype.getUnitById = function(unitId) {
    var unit;
    console.log('what are you loking??', unitId);
    console.log('units?', this.units);
    unit = this.units.filter(function(unit) {
      return unit.id === unitId;
    });
    return unit[0];
  };

  Room.prototype.startGame = function() {
    return this;
  };

  return Room;

})(Model);

Unit = (function(_super) {

  __extends(Unit, _super);

  function Unit(unitCode) {
    var unitStats;
    Unit.__super__.constructor.call(this);
    this.set({
      code: unitCode
    });
    unitCode = this.get('code');
    unitStats = this.getUnitStatsByCode(unitCode);
    this.set(unitStats);
    return;
  }

  Unit.prototype.getUnitStatsByCode = function(unitCode) {
    return Wol.UnitStats[unitCode];
  };

  return Unit;

})(Model);

ServerData = {
  rooms: [],
  users: []
};

ServerProtocol = {
  getCard: function() {
    var card;
    card = Math.random() * ServerData.cards;
    return this;
  },
  createRoom: function(roomName) {
    var room;
    room = new Room({
      name: roomName
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
    if (user.get('playerType' === PlayerType.PLAYER)) {
      ServerProtocol.assignEvents(user);
    }
    socket.on('disconnect', function() {
      room.removeUser(user);
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
    var generate, room, unit;
    room = ServerProtocol.getRoomById(roomId);
    room.startGame();
    generate = function(unitCode, user) {
      var unit;
      unit = ServerProtocol.addUnit({
        userId: user.id,
        roomId: room.id,
        unitCode: unitCode
      });
      return unit;
    };
    unit = generate('lemurian_marine', room.users[0]);
    ServerProtocol.moveUnit({
      unitId: unit.id,
      roomId: room.id,
      points: [
        {
          tileX: 2,
          tileY: 2
        }, {
          tileX: 3,
          tileY: 2
        }, {
          tileX: 4,
          tileY: 2
        }, {
          tileX: 4,
          tileY: 3
        }, {
          tileX: 4,
          tileY: 4
        }, {
          tileX: 4,
          tileY: 5
        }, {
          tileX: 4,
          tileY: 6
        }, {
          tileX: 3,
          tileY: 6
        }, {
          tileX: 2,
          tileY: 6
        }, {
          tileX: 1,
          tileY: 6
        }
      ]
    });
  },
  addUnit: function(data) {
    var room, roomId, unit, unitCode, user, userId;
    unitCode = data.unitCode;
    roomId = data.roomId;
    userId = data.userId;
    room = ServerProtocol.getRoomById(roomId);
    user = room.getUserById(userId);
    unit = room.addUnit(unitCode, userId);
    room.announce('addUnit', {
      userId: user.id,
      unitId: unit.id,
      unitCode: unit.get('code'),
      unitName: unit.get('name'),
      message: "" + (user.get('name')) + "'s " + (unit.get('name')) + " has been deployed to " + (room.get('name')) + ".",
      unitStats: unit.get('stats')
    });
    return unit;
  },
  moveUnit: function(data) {
    var point, points, room, roomId, unit, unitId, user, userId;
    roomId = data.roomId;
    unitId = data.unitId;
    points = data.points;
    room = ServerProtocol.getRoomById(roomId);
    unit = room.getUnitById(unitId);
    userId = unit.get('userId');
    user = room.getUserById(userId);
    point = points[points.length - 1];
    console.log(point);
    unit.set({
      tileX: point.tileX,
      tileY: point.tileY
    });
    return room.announce('moveUnit', {
      unitId: unitId,
      points: points
    });
  },
  assignEvents: function(user) {
    var socket;
    socket = user.get('socket');
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
