###
# Node Game Server
# ------------------------------------------------
# Author  : James Florentino
# E-mail  : j@jamesflorentino.com
# Github  : @jamesflorentino
###
# =========================================
# Global Variables
# =========================================
PORT = Number(process.env.PORT or 1337)
MAX_PLAYERS_PER_ROOM = 1
MAX_USERS_PER_ROOM = 2
PlayerType =
  SPECTATOR: 'spectator'
  PLAYER: 'player'
  ARBITER: 'arbiter'

# =========================================
# Libraries
# =========================================
io = require('socket.io').listen PORT
{Wol} = require './settings'


# =========================================
# UTILITIES
# =========================================
randomId = (len=10) ->
  chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
  result = ''
  while result.length < len
    i = Math.random() * chars.length
    result += chars.substr i, 1
  result

after = (ms, cb) -> setTimeout cb, ms
every = (ms, cb) -> setInterval cb, ms

# =========================================
# EXTENDED METHODS
# =========================================
Array::last = -> @[@length-1]
Array::first = -> @[0]
Array::at = (i) -> @[i]
Array::shuffle = -> @sort (a,b) -> Math.round(Math.random() * 10) % 2
Array::find = (cb) -> (@filter cb)[0]

# =========================================
# CLASSES
# =========================================

class EventDispatcher

  bind: (name, callback) ->
    @e or= {}
    @e[name] or= []
    @e[name].push callback
    this

  unbind: (name, callback) ->
    return if !@e
    if arguments.length is 0
      @e = {}
      return this
    return this if !@e[name]
    if !callback
      delete @e[name]
      return this
    index = @e[name].indexOf callback
    @e[name].splice index, 1
    return this

  trigger: (name, data) ->
    return this if !@e
    return this if !@e[name]
    @e[name].forEach (event) ->
      event data if event?
    this


# ===========================
# Model
# ===========================
class Model extends EventDispatcher

  id: randomId()
  attributes: []

  constructor: (attributes) ->
    @attributes = {}
    @id = randomId()
    @set attributes
    @initialize attributes
    return

  initialize: (options) ->
    return

  set: (props) ->
    for key of props
      @attributes[key] = props[key]
    this

  get: (propertyName) -> @attributes[propertyName]

class Collection extends Model

  collection: []
  initialize: ->
    @collection = []

  add: (model) ->
    @collection.push model

  remove: (model) ->
    @collection.splice(@collection.indexOf(model))

  find: (cb) -> (@collection.filter cb)[0]


# ===========================
# User
# ===========================

class User extends Model
  initialize: ->
    console.log "===================="
    console.log "User Event: #{@get 'name'} <#{@id}> enters a game"
    return

  announce: (eventName, message) ->
    @get('socket')
      .emit eventName, message
    this


# ===========================
# Rooms
# ===========================

class Room extends Model

  users: []
  units: []
  ready: false
  totalUsers: 0
  grid: undefined

  initialize: ->
    @users = []
    @units = []
    @ready = false
    @totalUsers = 0
    @grid = new HexGrid()
    @grid.generate 8, 8
    @setEvents()
    return
  
  # Room.addUser
  addUser: (user) ->
    @users.push user
    @totalUsers = @users.length
    this

  # Room.removeUser
  removeUser: (user) ->
    @users.splice @users.indexOf(user)
    this

  # Room.getUserById
  getUserById: (userId) ->
    user = @users.filter (user) -> user.id is userId
    user[0]

  announce: (eventName, data) ->
    console.log "===================="
    console.log "Room Event: #{eventName}"
    console.log data
    @users.forEach (user) ->
      user.announce eventName, data
    this

  # Room.addUnit
  addUnit: (unitCode, userId) ->
    unit = new Unit unitCode
    unit.set
      userId: userId
      roomId: @id
    unit.stats.set charge: 0
    @units.push unit
    unit

  # Room.getUnitById
  getUnitById: (unitId) ->
    unit = @units.filter (unit) -> unit.id is unitId
    unit[0]

  # Room.startGame
  startGame: -> this

  # Room.setEvents
  setEvents: ->
    return

  # Room.getNextTurn
  getNextTurn: ->
    roomId = @id
    roomName = @get 'name'
    units = @units
    activeUnit = undefined
    tickSpeed = 100
    console.log '\n', 'calculating next turn...'
    intervalId = every tickSpeed, =>
      highestCharge = 0
      units.forEach (unit) =>
        chargeSpeed = unit.getStat 'chargeSpeed'
        charge = unit.getStat 'charge'
        charge += chargeSpeed + Math.random() * 2
        unit.stats.set charge: charge
        highestCharge = charge if charge > highestCharge
        activeUnit = unit if charge > 100
        console.log "charging unit #{unit.id}...#{charge}"
        return
      # drop the shit if nobody has a chargespeed T_T
      if highestCharge is 0
        clearInterval intervalId
        return
      # if there's an active unit, execute unitTurn protocol
      if activeUnit?
        clearInterval intervalId
        activeUnit.stats.set charge: 0
        @set activeUnit: activeUnit
        @trigger 'unitTurn', unit: activeUnit
        console.log "unit selected", activeUnit
      return
    
  reset: ->
    @users = []
    @units = []




# ===========================
# Units
# ===========================

class Unit extends Model

  constructor: (unitCode) ->
    super()
    unitStats = Wol.UnitStats[unitCode]
    @set
      acted: false
      moved: false
      code: unitCode
      name: unitStats.name
    @stats = new Model()
    @stats.set unitStats.stats

  getStat: (statName) ->
    @stats.get statName

  move: (hex) ->
    @set
      tileX: hex.get 'tileX'
      tileY: hex.get 'tileY'

# ===========================
# Hex
# ===========================

class Hex extends Model

  initialize: ->
    @set cost: 1

  
# ===========================
# Grid
# ===========================

class HexGrid extends Collection

  generate: (cols, rows) ->
    tileY = 0
    while tileY < rows
      tileX = 0
      while tileX < cols
        @add new Hex tileX: tileX, tileY: tileY
        tileX++
      tileY++

  convertPoints: (points) ->
    return if !points
    return if !points.length
    points.map (point) =>
      @find (t) -> t.get('tileX') is point.tileX and t.get('tileY') is point.tileY





# =========================================
# Server Api
# =========================================

ServerData =
  rooms: []
  users: []

ServerProtocol =

  createRoom: (roomName) ->
    room = new Room name: roomName
    roomId = room.id

    room.bind 'unitTurn', (event) ->
      unit = event.unit
      unit.set moved: false, acted: false
      unit.stats.set actions: unit.stats.get('baseActions')
      unitId = unit.id
      userId = unit.get 'userId'
      user =  room.getUserById userId
      message = "#{roomName}: #{user.get 'name'}'s #{unit.get 'name'} is taking its turn."
      room.set activeUnit: unit
      room.announce 'unitTurn',
        unitId: unitId
        message: message
      console.log message

    ServerData.rooms.push room
    room
  
  getRoomById: (roomId) ->
    room = ServerData.rooms.filter (room) -> room.id is roomId
    room[0]

  joinRoom: (user, room) ->
    return if room is undefined
    
    userId = user.id
    userName = user.get 'name'
    roomId = room.id
    roomName = room.get 'name'
    socket = user.get 'socket'
    playerType = PlayerType.PLAYER

    # reject the user if the room is full
    if room.totalUsers > MAX_USERS_PER_ROOM
      user.announce 'roomError', message: 'Room is already full'
      return

    # add the user to the room
    room.addUser user
    totalUsers = room.totalUsers

    # set the player type to listen to the user's requests
    playerType = PlayerType.SPECTATOR if totalUsers > MAX_PLAYERS_PER_ROOM
    user.set playerType: playerType

    # spectators can only read from the system
    if user.get('playerType') is PlayerType.PLAYER
      ServerProtocol.assignEvents userId, roomId

    # when the user disconnects, remove him from the list
    socket.on 'disconnect', ->
      room.removeUser user
      if room.users.length is 0
        room.reset()
        return
      room.announce 'removeUser',
        roomId: roomId
        userId: userId
        userName: userName
        message: "#{playerType} #{userName} has left the game."
      console.log "#{userName} left #{roomName}"

    # tell the user that he is subscribed to the room's update
    user.announce 'joinRoom',
      roomId: roomId
      roomName: roomName
      message: "Hi #{userName}, you have joined #{roomName} <#{roomId}>"
  
    # announce the new user to the room list
    room.announce 'addUser',
      userId: userId
      userName: userName
      message: "#{playerType} #{userName} has joined the game."

    # start the game if the game has the minimum number of players
    if totalUsers >= MAX_PLAYERS_PER_ROOM
      ServerProtocol.startGame roomId
    room

  startGame: (roomId) ->
    room = ServerProtocol.getRoomById roomId

    # deploy a few units at the beginning of the game.
    unit = ServerProtocol.addUnit
      userId: room.users[0].id
      roomId: roomId
      unitCode: 'lemurian_marine'
      tileX: 3
      tileY: 3

    unitB = ServerProtocol.addUnit
      userId: room.users.last().id
      roomId: roomId
      unitCode: 'lemurian_marine'
      tileX: 4
      tileY: 3
      face: 'left'

    ServerProtocol.nextUnitTurn(roomId)

    return

  addUnit: (data) ->
    {unitCode, roomId, userId, tileX, tileY, face} = data
    room = ServerProtocol.getRoomById roomId
    user = room.getUserById userId
    unit = room.addUnit unitCode, userId
    unit.set tileX: tileX, tileY: tileY
    room.announce 'addUnit',
      userId: user.id
      unitId: unit.id
      tileX: tileX
      tileY: tileY
      unitCode: unit.get 'code'
      unitName: unit.get 'name'
      message: "#{user.get 'name'}'s #{unit.get 'name'} has been deployed to #{room.get 'name'}."
      face: face
      unitStats: unit.stats.attributes
    unit

  moveUnit: (data) ->
    {roomId, unitId, points} = data
    room = ServerProtocol.getRoomById roomId
    unit = room.getUnitById unitId
    userId = unit.get 'userId'
    user = room.getUserById userId
    # do some validations here
    # todo (...)
    point = points.last()
    unit.set
      tileX: point.tileX
      tileY: point.tileY
      moved: true
    userName = user.get 'name'
    unitName = unit.get 'name'
    tileX = points[points.length-1].tileX
    tileY=  points[points.length-1].tileY
    after 1000, ->
      room.announce 'moveUnit',
        unitId: unitId
        points: points
        message: "#{user.get 'name'}'s #{unit.get 'name'} is moving to hex(#{tileX}, #{tileY})"

  nextUnitTurn: (roomId) ->
    room = ServerProtocol.getRoomById roomId
    room.getNextTurn()

  assignEvents: (userId, roomId) ->
    room = ServerProtocol.getRoomById roomId
    user = room.getUserById userId
    socket = user.get 'socket'
    # ----------------------------------
    # EVENTS
    # ----------------------------------
    # moveUnit
    # when the client send a command to the server
    # stating that a unit has moved to a new tile destination
    # unitId: <String> the id of the unit
    # points: <Array> the tiles in which the unit is moving respectively
    socket.on 'moveUnit', (data) ->

      return console.log("invalid unit and points", data) if !data.unitId or !data.points
      {unitId, points} = data
      # cancel if the unit doesn't exist
      unit = room.getUnitById unitId
      return console.log("invalid unitId", unitId) if !unit
      # cancel if the specified unit isnt't the room's active unit
      return console.log("unit is not hte active unit") if room.get('activeUnit') isnt unit
      # do not issue comands if the client isnt' the acive player
      return console.log("user isn't the active user") if unit.get('userId') isnt userId
      # cancel if the sent grid doesn't exist too
      tiles = room.grid.convertPoints points
      return console.log("invalid points", points) if tiles.length is 0
      # verify the tile cost
      unitAction = unit.stats.get 'actions'
      moveCost = 0
      occupiedTiles = room.units.map (u) -> "#{u.get('tileX')}_#{u.get('tileY')}"
      conflictedTiles = []
      tiles.forEach (tile) ->
        tileId = "#{tile.get('tileX')}_#{tile.get('tileY')}"
        moveCost += tile.get('cost')
        conflictedTiles.push(tile) if occupiedTiles.indexOf(tileId) > -1
        return
        # check if the tiles have existing units on them.
      return console.log("cost of movement is < actions", unitId) if unitAction < moveCost
      return console.log("one of the tiles is occupied") if conflictedTiles.length > 0
      # update the unit with the diminished stats
      unit.stats.set actions: unitAction - moveCost
      # immediate set the unit's position the last tile destination
      unit.move tiles.last()
      ServerProtocol.moveUnit
        unitId: unitId
        roomId: roomId
        points: points
      return

    # moveUnitEnd
    # tells the server that the client just finished performaing an animation
    # the purpose of this event is to sync the clients of players.
    # unitId: <String> the id of the unit
    socket.on 'moveUnitEnd', (data) ->
      {unitId, type} = data
      unit = room.getUnitById unitId
      return if unit is undefined
      return if userId isnt unit.get('userId')
      # temporary for now
      ServerProtocol.nextUnitTurn roomId
      ###
      user.set readyState: true
      usersReady = room.users.filter (u) -> u.get 'readyState'
      return if usersReady.length < MAX_PLAYERS_PER_ROOM
      usersReady.forEach (u) -> user.set readyState: false
      activeUnit = room.get 'activeUnit'
      return if !activeUnit
      ###

    socket.on 'skipTurn', (data) =>
      {unitId} = data
      unit = room.getUnitById unitId
      # cancel if not the the active unit
      return if unit isnt room.get('activeUnit')
      # cancel
      ServerProtocol.nextUnitTurn roomId
    return


# CREATE DEFAULT ROOMS
testRoom = ServerProtocol.createRoom 'Asgard'

# =========================================
# Communication Protocols and Events
# =========================================
onConnect = (socket) ->

  user = null

  # before getting into the game system, the user must
  # supply the server with a username
  socket.on 'setUserName', (data) ->
    return if user?
    userName = data.userName
    user = new User socket: socket, name: userName
    user.announce 'setUserName',
      userId: user.id
      userName: user.get 'name'
    # DEBUG - deploy user to a default room
    ServerProtocol.joinRoom user, testRoom
    return

  # adds the user to an existing room by roomId
  socket.on 'joinRoom', (roomId) ->
    room = ServerProtocol.getRoomById roomId
    ServerProtocol.joinRoom user, room
    return
  return



# =========================================
# SOCKET CONFIGURATION
# =========================================
io.set 'brower client minification', true
io.set 'log level', 1
###
io.configure ->
  io.set 'transports', ['xhr-polling']
  io.set 'polling duration', 10
###
io.sockets.on 'connection', onConnect

