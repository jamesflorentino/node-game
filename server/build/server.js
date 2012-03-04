/*
# Node Game Server
# ------------------------------------------------
# Author  : James Florentino
# E-mail  : j@jamesflorentino.com
# Twitter : @jamesflorentino
# Github  : @jamesflorentino
# Dribble : @jamesflorentino
*/
var MAX_PLAYERS_PER_ROOM, MAX_USERS_PER_ROOM, Model, PORT, PlayerType, Room, ServerData, ServerProtocol, User, io, onConnect, randomId, testRoom, _,
  __hasProp = Object.prototype.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

PORT = Number(process.env.PORT || 1337);

MAX_PLAYERS_PER_ROOM = 2;

MAX_USERS_PER_ROOM = 3;

PlayerType = {
  SPECTATOR: 'spectator',
  PLAYER: 'player'
};

io = require('socket.io').listen(PORT);

_ = require('./underscore');

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

Model = (function() {

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
    console.log("user <" + this.id + "> is born");
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
    this.users.forEach(function(user) {
      return user.announce(eventName, data);
    });
    return this;
  };

  return Room;

})(Model);

ServerData = {
  rooms: [],
  users: []
};

ServerProtocol = {
  addUser: function(user) {
    ServerData.users.push(user);
  },
  createRoom: function(roomName) {
    var room;
    room = new Room({
      name: roomName
    });
    ServerData.rooms.push(room);
    console.log("Room " + roomName + " <" + room.id + "> is created.");
    return room;
  },
  getRoomById: function(roomId) {
    var room;
    room = ServerData.rooms.forEach(function(room) {
      return room.id === roomId;
    });
    return room[0];
  },
  joinRoom: function(user, room) {
    var playerType, socket, totalUsers, userId, userName;
    if (room === void 0) return;
    userId = user.id;
    userName = user.get('name');
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
      return room.announce('removeUser', {
        userId: userId,
        userName: userName,
        message: "" + playerType + " " + userName + " has left the game."
      });
    });
    user.announce('joinRoom', {
      roomId: room.id
    });
    room.announce('addUser', {
      userId: userId,
      userName: userName,
      message: "" + playerType + " " + userName + " has joined the game."
    });
    if (totalUsers >= MAX_PLAYERS_PER_ROOM) room.announce('startGame');
    return room;
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
