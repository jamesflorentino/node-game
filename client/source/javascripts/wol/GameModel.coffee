#= require settings

window.DEBUG = false

HOST = 'http://localhost:1337'
HOST = 'http://192.168.254.104:1337'

@Wol
@io

class Wol.Models.GameModel extends Wol.Models.Model

  init: ->
    @events = {}
    @rooms = new Wol.Collections.Collection()
    @users = new Wol.Collections.Collection()
    @user = new Wol.Models.Model

  connect: ->
    @socket = io.connect HOST
    @bindEvents()
    @setUserName ['James','Doris','Chloe','Blaise','Rico','Patrick'].random()
    this

  send: (eventName, data) ->
    console.log 'sending', eventName, data
    return if !@socket
    @socket.emit eventName, data
    this

  addUser: (data) ->
    @users.add new Wol.Models.Model(data)
    @trigger 'addUser', data

  getUserById: (userId) ->
    @users.find (user) -> user.get('userId') is userId
  
  bindEvents: ->
    @socket.on 'connect', (data) =>
      @trigger 'connect', data
      return

    @socket.on 'disconnect', (data) =>
      @trigger 'disconnect', data
      return

    @socket.on 'setUserName', (data) =>
      @user.set
        userId: data.userId
        userName: data.userName
      @trigger 'setUserName', data
      return

    @socket.on 'joinRoom', (data) =>
      @trigger 'joinRoom', data
      return

    @socket.on 'addUser', (data) =>
      @addUser data
      return

    @socket.on 'startGame', (data) =>
      @trigger 'startGame', data
    
    @socket.on 'removeUnit', (data) =>
      @trigger 'removeUnit', data

    @socket.on 'addUnit', (data) =>
      @trigger 'addUnit', data

    @socket.on 'moveUnit', (data) =>
      @trigger 'moveUnit', data

    @socket.on 'actUnit', (data) =>
      @trigger 'actUnit', data

    @socket.on 'unitTurn', (data) =>
      @trigger 'unitTurn', data

  setUserName: (userName) ->
    @socket.emit 'setUserName',
      userName: userName
      raceName: 'lemurian'
    this
  
