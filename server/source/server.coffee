###
# Node Game Server
# ------------------------------------------------
# Author	: James Florentino
# E-mail	: j@jamesflorentino.com
# Github	: @jamesflorentino
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

# =========================================
# Libraries
# =========================================
io = require('socket.io').listen PORT
_ = require './underscore'
{Wol} = require './settings'


# =========================================
# FUNCTIONS
# =========================================
randomId = (len=10) ->
	chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
	id = ''
	while id.length < len
		index = Math.random() * chars.length
		id += chars.substr index, 1
	id

Array::last = this[@length - 1]


# =========================================
# CLASSES
# =========================================
class Model
	id: randomId()
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

class User extends Model
	initialize: ->
		console.log "===================="
		console.log "User Event: #{@get 'name'} <#{@id}> enters a game"
		return

	announce: (eventName, message) ->
		@get('socket')
			.emit eventName, message
		this

class Room extends Model
	initialize: ->
		@users = []
		@units = []
		@ready = false
		@totalUsers = 0
		return
	
	addUser: (user) ->
		@users.push user
		@totalUsers = @users.length
		this

	removeUser: (user) ->
		@users.splice @users.indexOf(user)
		this

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

	addUnit: (unitCode, userId) ->
		unit = new Unit unitCode
		unit.set
			userId: userId
			roomId: @id
		@units.push unit
		unit

	getUnitById: (unitId) ->
		console.log 'what are you loking??', unitId
		console.log 'units?', @units
		unit = @units.filter (unit) -> unit.id is unitId
		unit[0]

	startGame: -> this


class Unit extends Model

	constructor: (unitCode) ->
		super()
		@set code: unitCode
		unitCode = @get 'code'
		unitStats = @getUnitStatsByCode unitCode
		@set unitStats
		return

	getUnitStatsByCode: (unitCode) ->
		Wol.UnitStats[unitCode]

# =========================================
# Server Api
# =========================================

ServerData =
	rooms: []
	users: []

ServerProtocol =

	getCard: ->
		card = Math.random() * ServerData.cards
		this

	createRoom: (roomName) ->
		room = new Room name: roomName
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
		ServerProtocol.assignEvents user if user.get 'playerType' is PlayerType.PLAYER

		# when the user disconnects, remove him from the list
		socket.on 'disconnect', ->
			room.removeUser user
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
		room.startGame()

		## deploy a few units on the beginning of the game.

		generate = (unitCode, user) ->
			unit = ServerProtocol.addUnit
				userId: user.id
				roomId: room.id
				unitCode: unitCode
			unit
		
		unit = generate 'lemurian_marine', room.users[0]
		ServerProtocol.moveUnit
			unitId: unit.id
			roomId: room.id
			points: [
				{ tileX: 2, tileY: 2 }
				{ tileX: 3, tileY: 2 }
				{ tileX: 4, tileY: 2 }
				{ tileX: 4, tileY: 3 }
				{ tileX: 4, tileY: 4 }
				{ tileX: 4, tileY: 5 }
				{ tileX: 4, tileY: 6 }
				{ tileX: 3, tileY: 6 }
				{ tileX: 2, tileY: 6 }
				{ tileX: 1, tileY: 6 }
			]
		return
	
	addUnit: (data) ->
		{unitCode} = data
		{roomId} = data
		{userId} = data
		room = ServerProtocol.getRoomById roomId
		user = room.getUserById userId
		unit = room.addUnit unitCode, userId
		room.announce 'addUnit',
			userId: user.id
			unitId: unit.id
			unitCode: unit.get 'code'
			unitName: unit.get 'name'
			message: "#{user.get 'name'}'s #{unit.get 'name'} has been deployed to #{room.get 'name'}."
			unitStats: unit.get 'stats'
		unit

	moveUnit: (data) ->
		{roomId} = data
		{unitId} = data
		{points} = data
		room = ServerProtocol.getRoomById roomId
		unit = room.getUnitById unitId
		userId = unit.get 'userId'
		user = room.getUserById userId
		# do some validations here
		# todo (...)
		point = points[points.length - 1]
		console.log point
		unit.set
			tileX: point.tileX
			tileY: point.tileY

		room.announce 'moveUnit',
			unitId: unitId
			points: points

		
	assignEvents: (user) ->
		socket = user.get 'socket'
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

