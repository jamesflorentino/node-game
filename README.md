# Node Multiplayer App

An on-going project for a turn-based game built in nodeJS and easelJS. Still nothing substantial to see here.


## setUserName

Sets the name of the user to the server, which enables other "write" API calls

**Server_Event**

	{
		userId: '1a2b3c4d5e6f7g8',
		userName: 'Bob'
	}

**Client_Request**

	{
		userName: 'Bob'
	}

## roomList

Sends the client the list of available rooms to join

**Server_Event**

	{
		rooms: [
			{ 
				roomId: '8g7f6e5d4c3b2a1',
				roomName: 'Room of Bob'
			}, {
				roomId: '1a2b3c4d5e6f7g8',
				roomName: 'Not room of bob'
			}
		]
	}


## joinRoom

Subscribes the user to the room

**Server_Event**

	{
		roomId: '8g7f6e5d4c3b2a1'
		roomName: 'The Room of Bob'
	}

**Client_Request**

	{
		roomId: '8g7f6e5d4c3b2a1'
	}


## addUser

Notifies the client that a user has joined the room

**Server_Event**

	{
		roomId: '8g7f6e5d4c3b2a1',
		userId: '1a2b3c4d5e6f7g8',
		userName: 'Bob',
		message: 'Bob has entered the room'
	}

## removeUser

Notifies the client that a user has left the room

**Server_Event**

	{
		roomId: '8g7f6e5d4c3b2a1',
		userId: '1a2b3c4d5e6f7g8',
		message: 'Bob has left the room'
	}

## playersReady

Notifies the client that the players are set and the game is ready to start.

**Server_Event**

	{
		message: 'Players of "Room of Bob" is ready'
	}

## addUnit

Notifies the client that a player's unit has spawned to the room.

**Server_Event**

	{
		unitId: 'abcde123',
		unitName: 'Lemurian Marine',
		unitCode: 'lemurian_marine',
		unitStats: {
			maxHealth: 100,
			health: 100,
			maxEnergy: 50,
			energy: 50,
			maxActions: 10,
			actions: 10,
			turnSpeed: 20
		}

	}
