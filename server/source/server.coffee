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

after = (ms, cb) -> setTimeout cb, ms

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

	initialize: ->
		@users = []
		@units = []
		@ready = false
		@totalUsers = 0
		@setEvents()
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
		unit = @units.filter (unit) -> unit.id is unitId
		unit[0]

	startGame: -> this

	setEvents: ->
		@bind 'moveUnitEnd', (data) =>
			{unitId} = data
			# set the user's readyState to true
			# which implies the animation has finished loading.
			unit = @getUnitById unitId
			userId = unit.get 'userId'
			user = @getUserById userId
			user.set readyState: true
			# check if all the users's readyState is true
			usersReady = @users.filter (user) ->
				user.get 'readyState'
			# dispatch an event that tells all players are ready for the next move
			return if usersReady.length < MAX_PLAYERS_PER_ROOM
			# re-set their readyStates again to false
			usersReady.forEach (user) -> user.set readyState: false
			@trigger 'readyUsers',
				users: usersReady
				type: 'move' # either `move` or `act`
			return
		return
	
	getNextTurn: ->
		activeUnit = undefined
		# iterate all the units
		while !activeUnit  # either null or undefined
			highestCharge = 0
			@units.forEach (unit) ->
				chargeSpeed = unit.getStat 'chargeSpeed'
				console.log chargeSpeed, unit.stats
				charge = unit.getStat 'charge'
				charge += chargeSpeed
				unit.set charge: charge
				# here we check which unit wins the highest value
				# in this iteration
				if charge > highestCharge
					highestCharge = charge
					activeUnit = unit
			# reset the activeUnit value back to undefined
			# if the highestCharge didn't reach the max value
			# hence, restarting the lottery again.
			activeUnit = undefined if highestCharge < 100
			# prevent the loop from going forever 
			# if no one won the lottery
			break if highestCharge is 0
		@trigger 'unitTurn', unit: activeUnit

	reset: ->
		@users = []
		@units = []




# ===========================
# Units
# ===========================

class Unit extends Model

	stats: new Model()
	constructor: (unitCode) ->
		super()
		@set code: unitCode
		unitCode = @get 'code'
		unitStats = Wol.UnitStats[unitCode]
		@set
			name: unitStats.name
		@stats.set unitStats.stats
		return

	getStat: (statName) ->
		@stats.get statName

	
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
		roomId = room.id
		room.bind 'readyUsers', (event) ->
			switch event.type
				when 'move'
					# calculate the next turn
					after 1000, ->
						ServerProtocol.nextUnitTurn roomId

		room.bind 'unitTurn', (event) ->
			unit = event.unit
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
			console.log 'playertype go assign yours hit!'
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
				{ tileX: 3, tileY: 3 }
				{ tileX: 4, tileY: 3 }
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
			unitStats: unit.stats.attributes
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

		userName = user.get 'name'
		unitName = unit.get 'name'
		tileX = points[points.length-1].tileX
		tileY=  points[points.length-1].tileY
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
		socket.on 'moveUnitEnd', (data) ->
			{unitId} = data
			room.trigger 'moveUnitEnd', unitId: unitId
			return
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

