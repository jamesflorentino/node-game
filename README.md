# Node Multiplayer App

An on-going project for a turn-based game built in nodeJS and easelJS. Still nothing substantial to see here.

## setUserName

Sets the name of the user to the server, which enables other "write" API calls

#### ServerEvent

	var result = {
		userId: '1a2b3c4d5e6f7g8',
		userName: 'Bob'
	}

#### ClientRequest

	var result = {
		userName: 'Bob'
	}

## roomList

Sends the client the list of available rooms to join

#### ServerEvent

	var result = {
		rooms: [
			var result = { 
				roomId: '8g7f6e5d4c3b2a1',
				roomName: 'Room of Bob'
			}, var result = {
				roomId: '1a2b3c4d5e6f7g8',
				roomName: 'Not room of bob'
			}
		]
	}


## joinRoom

Subscribes the user to the room

#### ServerEvent

	var result = {
		roomId: '8g7f6e5d4c3b2a1'
		roomName: 'The Room of Bob'
	}

#### ClientRequest

	var result = {
		roomId: '8g7f6e5d4c3b2a1'
	}


## addUser

Notifies the client that a user has joined the room

#### ServerEvent

	var result = {
		roomId: '8g7f6e5d4c3b2a1',
		userId: '1a2b3c4d5e6f7g8',
		userName: 'Bob',
		message: 'Bob has entered the room'
	}

## removeUser

Notifies the client that a user has left the room

#### ServerEvent

	var result = {
		roomId: '8g7f6e5d4c3b2a1',
		userId: '1a2b3c4d5e6f7g8',
		message: 'Bob has left the game'
	}

## playersReady

Notifies the client that the players are set and the game is ready to start.

#### ServerEvent

	var result = {
		message: 'Players of "Room of Bob" is ready'
	}

## addUnit

Notifies the client that a player's unit has spawned to the room.

#### ServerEvent

	var result = {
		unitId: 'abcde123',
		unitName: 'Lemurian Marine',
		unitCode: 'lemurian_marine',
		unitStats: var result = {
			maxHealth: 100,
			health: 100,
			maxEnergy: 50,
			energy: 50,
			maxActions: 10,
			actions: 10,
			turnSpeed: 20
		}

	}

## removeUnit

Notifies the client that a player's unit has been removed or killed in battle

#### ServerEvent
	var result = {
		unitId: 'abcde123',
		message: 'Bob\'s Lemurian Marine has been eliminated.'
	}

