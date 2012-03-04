#= require settings
#= require wol/AssetLoader

window.DEBUG = false

@Wol
@io

class Wol.Models.GameModel extends Wol.Models.Model

  init: ->
    @events = {}
    @rooms = []
    @user = new Wol.Models.Model
    @socket = io.connect 'http://localhost:1337'
    @createEvents().bindEvents()
    @setUserName ['James','Doris','Chloe','Blaise','Rico','Patrick'].random()

  
  createEvents: ->
    user = @user
    socket = @socket
    @events =
      connect: =>
        console.log 'connect'
        this

      disconnect: =>
        console.log 'disconnect'
        this

      setUserName: (data) =>
        user.set id: data.userId, name: data.userName
        console.log 'setName', data
        this

      joinRoom: (data) =>
        console.log 'joinRoom', data
        this

    this
  
  bindEvents: ->
    socket = @socket
    socket.on 'connect', @events.connect
    socket.on 'disconnect', @events.disconnect
    socket.on 'setUserName', @events.setUserName
    socket.on 'joinRoom', @events.joinRoom
    this

  setUserName: (userName) ->
    @socket.emit 'setUserName',
      userName: userName
    this
  
