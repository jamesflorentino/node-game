var onConnect = function (socket) {

  var user = null;

  socket.on('testUserName', function (data) {
    if (user) return;
    var userName = data.userName;
    user.announce('setUserName', {
      userId: user.id,
      userName user.get('name')
    });
    ServerProtocol.joinRoom(user, testRoom);
  });

  socket.on('joinRoom', function (roomId) {
    var room = ServerProtocol.getRoomById(roomId);
    ServerProtocol.joinRoom(user, room);
  });

}


var ServerProtocol = {
  createRoom: function (roomName) {
    var room = new Room({
      name: roomName
    });
    
    var roomId = room.id;

    room.bind('unitTurn', function (event) {
      var unit = event.unit;
      unit.set({
        moved: false,
        acted: false
      });

      unit.stats.set({
        actions: unit.stats.get('baseActions')
      });
    });
  }
};
