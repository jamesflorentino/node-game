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
MAX_PLAYERS_PER_ROOM = 2
MAX_USERS_PER_ROOM = 3
PlayerType =
	SPECTATOR: 'spectator'
	PLAYER: 'player'

# =========================================
# Libraries
# =========================================
io = require('socket.io').listen PORT
_ = require './underscore'

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


# =========================================
# CLASSES
# =========================================
class Model
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
		console.log "user <#{@id}> is born"
		return

	announce: (eventName, message) ->
		@get('socket')
			.emit eventName, message
		this

class Room extends Model
	initialize: ->
		@users = []
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
		@users.forEach (user) ->
			user.announce eventName, data
		this


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

	addUser: (user) ->
		ServerData.users.push user
		return

	createRoom: (roomName) ->
		room = new Room name: roomName
		ServerData.rooms.push room
		console.log "Room #{roomName} <#{room.id}> is created."
		room
	
	getRoomById: (roomId) ->
		room = ServerData.rooms.forEach (room) -> room.id is roomId
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
	
		# announce the new user to the room list
		room.announce 'addUser',
			userId: userId
			userName: userName
			message: "#{playerType} #{userName} has joined the game."
		console.log "#{userName} joined #{roomName}"


		# start the game if the game has the minimum number of players
		room.announce 'startGame' if totalUsers >= MAX_PLAYERS_PER_ROOM
		room

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

