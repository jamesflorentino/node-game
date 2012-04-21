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
MAX_USERS_PER_ROOM = 3
PlayerType =
  SPECTATOR: 'spectator'
  PLAYER: 'player'
  ARBITER: 'arbiter'

# prototypes
# /////////////////////////////////////////////////
Array::last = -> @[@length-1]
Array::first = -> @[0]
Array::at = (i) -> @[i]

# collection methods
# /////////////////////////////////////////////////
Array::shuffle = -> @sort (a,b) -> Math.round(Math.random() * 10) % 2
Array::select = (cb) -> item for item, i in this when cb item
Array::detect = (cb) -> @select(cb)[0]
Array::find = (cb) -> (@select cb)[0]
Array::each = (cb) ->
  cb child for child, i in this

# libraries
io = require('socket.io').listen PORT
{Wol} = require './settings'


# global functions
randomId = (len=10) ->
  chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
  result = ''
  while result.length < len
    i = Math.random() * chars.length
    result += chars.substr i, 1
  result
after = (ms, cb) -> setTimeout cb, ms
every = (ms, cb) -> setInterval cb, ms

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
    @e[name].each (event) ->
      event data if event?
    this

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
  initialize: ->
    @collection = []

  add: (data) ->
    if data instanceof Array
      data.each (item) =>
        if item instanceof Model
          @collection.push item
        else
          @collection.push(new Model(item))
      return
    @collection.push data

  removeById: (id) ->
    model = @collection.select (item) -> item.id is id
    @collection.splice @collection.indexOf(model), 1
  
  remove: (model) ->
    @collection.splice(@collection.indexOf(model))

  find: (cb) -> @collection.find cb

  getAttributes: ->
    @collection.map (model) -> model.attributes

class User extends Model
  initialize: ->
    console.log "User Event: #{@get 'name'} <#{@id}> enters a game"
    return

  announce: (eventName, message) ->
    @get('socket')
      .emit eventName, message
    this

class Room extends Model
  users: []
  units: []
  logs: []
  ready: false
  totalUsers: 0
  grid: undefined

  initialize: ->
    @users = []
    @units = []
    @logs = []
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
    @totalUsers = @users.length
    this

  # Room.getUserById
  getUserById: (userId) ->
    user = @users.select (user) -> user.id is userId
    user[0]

  getUnitByTileId: (tileId) ->
    @units.find (unit) ->
      tileId is "#{unit.get('tileX')}_#{unit.get('tileY')}"

  getUnitByCoord: (x, y) ->
    unit for unit in @units when unit.get('tileX') is x and unit.get('tileY') is y

  announce: (eventName, data) ->
    console.log "Room Event: #{eventName}"
    console.log JSON.stringify data
    @logs.push
      eventName: eventName
      data: data
    @users.each (user) ->
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
    unit = @units.select (unit) -> unit.id is unitId
    unit[0]

  # Room.startGame
  startGame: -> this
  
  endGame: ->
    # for now check who stands the last.
    unit = (unit for unit in @units when unit.dead is false).first()
    userId = unit.get 'userId'
    @trigger 'endGame',
      userId: userId
  
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
      units.each (unit) =>
        return if unit.getStat('health') is 0
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
        console.log "unit selected", JSON.stringify(activeUnit)
      return

  getLivingUnits: ->
    what = unit for unit in @units when unit.dead is false
    what = @units.select (unit) -> unit.dead is false
    what

  getPlayers: ->
    @users.map (user) ->
      user.get('playerType') is PlayerType.PLAYER

  reset: ->
    @units = []
    console.log "deleting users.. from room #{@get 'name'} <#{@id}>"
    @users.each (user) ->
      socket = user.get 'socket'
      socket.disconnect()
      console.log "deleted #{user.get('name')} <#{user.id}>..."
    @set ready: false
    @users = []
    @totalUsers = @users.length

class Unit extends Model
  constructor: (unitCode) ->
    super()
    unitStats = Wol.UnitStats[unitCode]
    @set
      acted: false
      moved: false
      code: unitCode
      name: unitStats.name
      role: unitStats.role
    @stats = new Model()
    @stats.set unitStats.stats
    unitCommands = Wol.UnitCommands[unitCode]
    @commands = new Collection()
    @commands.add unitCommands
    @dead = false

  # invoke this to perform a deduction/addition to the unit's stats
  # returns the unit's current stats
  receiveDamageData: (damageData) ->
    stats =
      health: @getStat 'health'
      shield: @getStat 'shield'
      armor: @getStat 'armor'
    if stats.shield > 0
      stats.shield -= damageData.shield
      stats.shield = Math.max 0, stats.shield
      @stats.set shield: stats.shield
    else if stats.armor > 0
      stats.armor -= damageData.armor
      stats.armor = Math.max 0, stats.armor
      @stats.set armor: stats.armor
    else
      stats.health -= damageData.health
      stats.health = Math.max 0, stats.health
      @stats.set health: stats.health
    health: @getStat 'health'
    shield: @getStat 'shield'
    armor: @getStat 'armor'

  # apply/filter bonuses/penalties from the damageData
  filterDamageData: (damageData) ->
    damage =
      health: 0
      shield: 0
      armor: 0
    if @getStat('shield') > 0
      damage.shield = damageData.shield
    else if @getStat('armor') > 0
      damage.armor = damageData.armor
    else if @getStat('health') > 0
      damage.health = damageData.health
    # todo: bonus/penalty conditions here
    # e.g. damage.health = damage.health * 2 if @statusEffects.get('burning')
    health: damage.health
    shield: damage.shield
    armor: damage.armor

  getDamageData: (commandCode) ->
    command = @getCommandByCode commandCode
    damage = command.get 'damage'
    health = damage.health.value
    shield = damage.shield.value
    armor = damage.armor.value
    # add bonuses
    health += Math.round Math.random() * damage.health.bonus
    shield += Math.round Math.random() * damage.shield.bonus
    armor += Math.round Math.random() * damage.armor.bonus
    # damage data
    health: health
    shield: shield
    armor: armor

  setStat: (data) ->
    @stats.set data

  getStat: (statName) ->
    @stats.get statName

  getStats: ->
    @stats.attributes

  getCommandByCode: (commandCode) ->
    @commands.find (command) ->
      command.get('code') is commandCode

  move: (hex) ->
    console.log 'move unit to ....', JSON.stringify(hex.attributes)
    @set
      tileX: hex.get 'tileX'
      tileY: hex.get 'tileY'

class Hex extends Model
  initialize: ->
    @set cost: 1

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
      @find (t) -> t.get('tileX') is (point.tileX or point.x) and t.get('tileY') is (point.tileY or point.y)

ServerData =
  rooms: []
  users: []

ServerProtocol =
  createRoom: (roomName) ->
    room = new Room name: roomName
    roomId = room.id
    # endGame
    room.bind 'endGame', (event) ->
      {userId, message} = event
      room.announce 'endGame',
        userId: userId
        message: message
    # unitTurn
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
        stats:
          actions: unit.getStat 'actions'
      console.log message
    ServerData.rooms.push room
    room
  
  getRoomById: (roomId) ->
    room = ServerData.rooms.select (room) -> room.id is roomId
    room[0]
  
  joinRoom: (user, room, raceName) ->
    return if room is undefined
    userId = user.id
    userName = user.get 'name'
    roomId = room.id
    roomName = room.get 'name'
    socket = user.get 'socket'
    playerType = PlayerType.PLAYER
    user.set raceName: raceName
  
    # reject the user if the room is full
    # if room.totalUsers > MAX_USERS_PER_ROOM
    if room.totalUsers >= MAX_USERS_PER_ROOM
      user.announce 'roomError', message: 'Room is already full'
      socket.disconnect()
      return
  
    # add the user to the room
    room.addUser user
    totalUsers = room.totalUsers

    # set the player type to listen to the user's requests
    playerType = PlayerType.SPECTATOR if totalUsers > MAX_PLAYERS_PER_ROOM
    user.set playerType: playerType

    # spectators can only read from the system
    if user.get('playerType') is PlayerType.PLAYER
      players = room.getPlayers()
      user.set playerNumber: players.length
      ServerProtocol.assignEvents userId, roomId

    socket.on 'reconnect', ->
      console.log "#{userName} reconnected to #{roomName}"

    # when the user disconnects, remove him from the list
    socket.on 'disconnect', ->
      console.log "#{userName} disconnected from #{roomName}"
      room.removeUser user
      # disconnect all clients then delete the room
      # if there's no more players in it.
      if room.getPlayers().length < MAX_PLAYERS_PER_ROOM
        room.announce 'endGame',
          message: "Player #{userName} has left. The game has ended."
        console.log "Deleting room #{roomName} <#{roomId}>"
        room.reset()
        return
      room.announce 'removeUser',
        roomId: roomId
        userId: userId
        userName: userName
        message: "#{playerType} #{userName} has left the game."
      # end

    # tell the user that he is subscribed to the room's update
    user.announce 'joinRoom',
      roomId: roomId
      roomName: roomName
      message: "Hi #{userName}, you have joined #{roomName} <#{roomId}>"

    # populate the earlier list of users to the client
    room.users.each (u) ->
      return if u is user
      user.announce 'addUser',
        userId: u.id
        userName: u.get 'name'
        playerNumber: u.get 'playerNumber'
        playerType: u.get 'playerType'
        raceName: u.get 'raceName'
        message: "#{playerType} #{userName} has joined the game."

    # announce the new user to the room list
    room.announce 'addUser',
      userId: userId
      userName: userName
      playerNumber: user.get 'playerNumber'
      playerType: user.get 'playerType'
      raceName: user.get 'raceName'
      message: "#{playerType} #{userName} has joined the game."

    # start the game if the game has the minimum number of players
    if totalUsers >= MAX_PLAYERS_PER_ROOM
      if room.get('ready') is true
        ServerProtocol.updateClient user, room
        return
      room.set ready: true
      ServerProtocol.startGame roomId
    room

  updateClient: (user, room) ->
    userId = user.id
    socket = user.get 'socket'
    roomId = room.id
    user.announce 'startGame',
      message: 'You are late'
    room.units.each (unit) ->
      user.announce 'addUnit',
        userId: unit.get 'userId'
        unitId: unit.id
        tileX: unit.get 'tileX'
        tileY: unit.get 'tileY'
        unitCode: unit.get 'code'
        unitName: unit.get 'name'
        unitRole: unit.get 'role'
        message: "#{user.get 'name'}'s #{unit.get 'name'} has been deployed to #{room.get 'name'}."
        face: unit.get 'face'
        unitStats: unit.stats.attributes
        unitCommands: unit.commands.getAttributes()
      return
    return

  startGame: (roomId) ->
    room = ServerProtocol.getRoomById roomId
    room.announce 'startGame',
      message: 'Game has started'
    players = room.users.select (u) ->
      u.get('playerType') is PlayerType.PLAYER
    # deploy a few units at the beginning of the game.
    unit = ServerProtocol.addUnit
      userId: players.first().id
      roomId: roomId
      unitCode: 'lemurian_marine'
      tileX: 0
      tileY: 2

    unitB = ServerProtocol.addUnit
      userId: players.last().id
      roomId: roomId
      unitCode: 'lemurian_marine'
      tileX: 1
      tileY: 2
      face: 'left'

    unit.setStat
      baseShield: 100
      shield: 20

    room.announce 'updateUnit',
      unitId: unit.id
      stats: unit.getStats()

    after 10, ->
      room.getNextTurn()

    return

  addUnit: (data) ->
    {unitCode, roomId, userId, tileX, tileY, face} = data
    room = ServerProtocol.getRoomById roomId
    user = room.getUserById userId
    unit = room.addUnit unitCode, userId
    unit.set tileX: tileX, tileY: tileY, face: face
    room.announce 'addUnit',
      userId: user.id
      unitId: unit.id
      tileX: tileX
      tileY: tileY
      unitCode: unit.get 'code'
      unitName: unit.get 'name'
      unitRole: unit.get 'role'
      message: "#{user.get 'name'}'s #{unit.get 'name'} has been deployed to #{room.get 'name'}."
      face: face
      unitStats: unit.stats.attributes
      unitCommands: unit.commands.getAttributes()
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
      tileX: point.tileX or point.x
      tileY: point.tileY or point.y
    userName = user.get 'name'
    unitName = unit.get 'name'
    tileX = points[points.length-1].tileX
    tileY=  points[points.length-1].tileY
    # check for the last tile and remove any unit located there.
    after 1000, ->
      room.announce 'moveUnit',
        unitId: unitId
        points: points
        message: "#{user.get 'name'}'s #{unit.get 'name'} is moving to hex(#{tileX}, #{tileY})"

  assignEvents: (userId, roomId) ->
    room = ServerProtocol.getRoomById roomId
    user = room.getUserById userId
    socket = user.get 'socket'
    # actUnit
    # unitId - the unit's id
    # points - the tiles that are affected by the command
    # commandCode - a static name for a certain command.
    socket.on 'actUnit', (data) ->
      {unitId, points, commandCode} = data
      return console.log('no unitId')if !unitId
      return console.log('no commandCode') if !commandCode
      return console.log('no points/tiles') if !points
      return console.log('points length is 0') if points.length is 0
      # disregard if the unitId doesn't exist
      unit = room.getUnitById unitId
      return console.log('invalid unitId') if !unit
      # disregard if unit is not the active one
      return console.log("unit is not hte active unit") if room.get('activeUnit') isnt unit
      # disregard if the points given does not exist
      tiles = room.grid.convertPoints points
      return console.log('invalid points', JSON.stringify(points)) if tiles.length is 0
      # disregard if insufficient AP
      command = unit.getCommandByCode commandCode
      return if unit.getStat('actions') - command.get('cost') < 0
      # targets will be the affeced units from the operation
      damageData = unit.getDamageData commandCode
      targets = []
      # deduct AP
      unit.setStat actions: unit.getStat('actions') - command.get('cost')
      # populate the target list
      points.each (point) ->
        targetUnit = undefined
        (->
          for u in room.units
            console.log 'room unit....', u.id, JSON.stringify(unit.attributes)
            if u.get('tileX') is point.tileX && u.get('tileY') is point.tileY
              targetUnit = u
              console.log 'found target unit', u.id, JSON.stringify(u.attributes)
              break
        )()
        return console.log('no target unit') if !targetUnit
        return console.log('target is dead') if targetUnit.dead is true
        totalDamageData = targetUnit.filterDamageData damageData
        targetUnitStats = targetUnit.receiveDamageData totalDamageData
        console.log '/////////////////'
        console.log 'damage to unit', targetUnit.id
        console.log totalDamageData
        console.log '.'
        targets.push
          unitId: targetUnit.id
          damage: totalDamageData
          stats: targetUnitStats
        targetUnit.dead = true if targetUnit.getStat('health') is 0
      return console.log('no targets detected') if targets.length is 0
      after 1000, ->
        room.announce 'actUnit',
          unitId: unitId
          targets: targets
          commandCode: commandCode
      this
    # moveUnit
    # when the client send a command to the server
    # stating that a unit has moved to a new tile destination
    # unitId: <String> the id of the unit
    # points: <Array> the tiles in which the unit is moving respectively
    socket.on 'moveUnit', (data) ->
      console.log '//////////////////////////////////////////'
      console.log 'moveUnit event..'
      console.log '//////////////////////////////////////////'
      return console.log("invalid unit and points", data) if !data.unitId or !data.points
      {face, unitId, points} = data
      # cancel if the unit doesn't exist
      # cancel if the specified unit isnt't the room's active unit
      # do not issue comands if the client isnt' the acive player
      unit = room.getUnitById unitId
      return console.log("invalid unitId", unitId) if !unit
      return console.log("unit is not hte active unit") if room.get('activeUnit') isnt unit
      return console.log("user isn't the active user") if unit.get('userId') isnt userId
      # if the grid doesn't exist, have the unit re-take its turn.
      tiles = room.grid.convertPoints points
      if tiles.length is 0
        room.announce 'unitTurn',
          unitId: unit.id
          stats:
            actions: unit.getStat 'actions'
          message: "<Invalid tiles> #{user.get('name')}'s #{unit.get('name')} is continuing its turn."
        return
      # verify the tile cost movement
      totalActions = 0
      moveRadius = unit.getStat 'moveRadius'
      conflictedTiles = []
      tiles.each (tile) ->
        tileId = "#{tile.get('tileX')}_#{tile.get('tileY')}"
        totalActions += tile.get 'cost'
        occupiedUnit = room.getUnitByTileId tileId
        # check if a unit exists in the tile
        if occupiedUnit?
          # if the unit is dead then we allow the user to walk over it.
          # dead units can be resurrected or consumed by other races. (future plan)
          if occupiedUnit.dead isnt true
            conflictedTiles.push(tile)
        return
      # return console.log("cost of movement is < actions", unitId) if unit.getStat('actions') < totalActions
      return console.log("total tile cost is greater than the moveRadius") if totalActions > moveRadius
      return console.log("one of the tiles is occupied") if conflictedTiles.length > 0
      # update the unit with the diminished stats
      unit.set face: face
      unit.setStat
        actions: unit.getStat('actions') - 1
      # immediate set the unit's position the last tile destination
      console.log '..'
      console.log 'setting unit point', points
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
      console.log '//////////////////////////////////////////'
      console.log 'animation end  event..'
      console.log '//////////////////////////////////////////'
      {unitId, type} = data
      unit = room.getUnitById unitId
      # if the sender isn't the unit owner.
      return if userId isnt unit.get('userId')
      # if invalid unitId
      return if unit is undefined
      # if unit isn't the active unit
      return if unit isnt room.get('activeUnit')
      # check if there's an existing unit on top of it
      tileX = unit.get 'tileX'
      tileY = unit.get 'tileY'
      deadUnit = room.units.find (u) ->
        (u isnt unit) and (u.get('tileX') is tileX and u.get('tileY') is tileY) and (u.dead is true)
      # reomve the unit from the client
      if deadUnit?
        room.announce 'removeUnit',
          unitId: deadUnit.id
      # check if there's no more opponent left.
      if room.getLivingUnits().length <= 1
        room.endGame()
        return
      # let the unit proceed with the game
      if unit.getStat('actions') > 0
        room.announce 'unitTurn',
          unitId: unit.id
          stats:
            actions: unit.getStat 'actions'
          message: "#{user.get('name')}'s #{unit.get('name')} is continuing its turn."
      else
        room.getNextTurn()
      return
    # skipTurn
    socket.on 'skipTurn', (data) ->
      {unitId} = data
      unit = room.getUnitById unitId
      return if unit is undefined
      return if userId isnt unit.get('userId')
      return if unit isnt room.get('activeUnit')
      room.getNextTurn()
    return

testRoom = ServerProtocol.createRoom 'Asgard'

io.set 'brower client minification', true
io.set 'log level', 1
io.configure ->
  io.set 'transports', ['websocket']
  #io.set 'transports', ['xhr-polling']
  #io.set 'polling duration', 10
io.sockets.on 'connection', (socket) ->
  user = null
  # before getting into the system, the user must
  # supply the server with a username
  socket.on 'setUserName', (data) ->
    return if user?
    {userName} = data
    user = new User socket: socket, name: userName
    user.announce 'setUserName',
      userId: user.id
      userName: user.get 'name'
    raceName = 'lemurian'
    ServerProtocol.joinRoom user, testRoom, raceName
    return
  # joinRoom
  socket.on 'joinRoom', (roomId, options) ->
    if options?
      {raceName} = options
    raceName or= 'lemurian'
    room = ServerProtocol.getRoomById roomId
    ServerProtocol.joinRoom user, room
    return
  return
