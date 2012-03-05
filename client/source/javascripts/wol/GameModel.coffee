#= require settings

window.DEBUG = false

HOST = 'http://localhost:1337'

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

			addUser: (data) =>
				console.log 'addUser', data
				user = new Wol.Models.Model data
				@users.add user
				this

			playersReady: (data) =>
				console.log 'playersReady', data
				this

		this
	
	bindEvents: ->
		socket = @socket
		socket.on 'connect', @events.connect
		socket.on 'disconnect', @events.disconnect
		socket.on 'setUserName', @events.setUserName
		socket.on 'joinRoom', @events.joinRoom
		socket.on 'addUser', @events.addUser
		this

	setUserName: (userName) ->
		@socket.emit 'setUserName',
			userName: userName
		this
	
