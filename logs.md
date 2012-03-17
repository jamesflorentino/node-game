# Logs

## TODOS

1. **server** / Instigate a command that spanws a unit in the room/game. server.coffee line 101 (finished)
2. **server** / don't put announcements on the class logic. They should be inside the ServerProtocol methods. (finished)
3. **client** / on the `moveUnit` protocol, make sure to send a `moveUnitEnd` call to the server, with the Id of the unit that moved. This is to ensure that the game can progress forward and that ALL clients received the command. code example (finished) :

    socket.send("moveUnitEnd", {
      unitId: "1a2b3c4d5e6f7"
    });

4. **server** / bind events triggered from the `Room` class. This allows us to neatly organize events in the `ServerProtocol`(finished)
5. **client** / set the properties like `walkSpeed` as a prototype property instead to increase performance.(finished)
6. **server** / calculate the room's next turn. The protocol name will be `turnList` which returns the turn list. And `unitTurn` which tells the client which unit is ready to move. pseudo-code: (finished)
 
    function getNextTurn() {
      // create a copy of their charge property and name it tentativeCharge
      // whoever gets the highest possible value for their tempCharge wins the "lottery"
      // with this we now have an active unit's turn to send to the client. Hold on to this edata.
      // now we move onto getting a tentative turn list for the client UI to display.
      // 
    }

7. **server** / what to do if no one wins the next turn? do I dispatch an event to the client specifyin that the game has ended? If so, I can also use this to tell the clients who got the highest score. :) woot woot

8. **server** / When a user leaves a room, and there's still a player in it, kill all of the player's units for now since this is a two player match only. e.g.

    socket.send("removeUnit", {
      unitId: "1a2b3c4d5e6f7"
    });

9. **server** Before sending a `unitTurn` event from a Room, check first if there's an `activeUnit`. If one exists, then we should first check if the unit has some actions left. The unit will need to deplete all his Action Points. or Press the Skip button. Alternatively, we can also set a `.moved` and `.acted` property to the unit. This will prevent the unit from acting two moves or two unit actions.


## Updates

1. Finished the moveUnit implementation from server to client.
2. When the player logs out and the room is empty, it will reset itself - removing any existing users and units from the room.
3. Implemented a way to properly manage adjacent tile selection in the client.


## What I learned

- **client** / Always bind events from the `socket.io` event handler to the main `GameModel`! You will use this to dispatch/trigger events for the `GameView`.
- **server** / `userId` should only be accessed within a `Room` class. Do not store/retrieve them in the `ServerData` object.
- **server** / Instances of the `User` and `Unit` classes both belong to the same level of array in the `Room` class. Ideally, the `units` array should be under `User` class for easy access. However, having it on the `Room` class allows us to apply quick fixes for user-disconnection scenarios. e.g. Transfer the `userId` attribute of the `Unit` class to the room AI, or to another player present in the room.
- **client** / before binding an ___event___ to an object **unbind** it first!!!
- **client** / ALWAYS instantiate a new Model when creating a new View
