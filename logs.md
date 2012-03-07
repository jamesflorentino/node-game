# Logs

## TODOS

- **server** Instigate a command that spanws a unit in the room/game. server.coffee line 101 (finished)
- **server** don't put announcements on the class logic. They should be inside the ServerProtocol methods. (finished)

## Updates

- Finished the moveUnit implementation from server to client.

## What I learned

- **client** / Always bind events from the `socket.io` event handler to the main `GameModel`! You will use this to dispatch/trigger events for the `GameView`.
- **server** / `userId` should only be accessed within a `Room` class. Do not store/retrieve them in the `ServerData` object.
- **server** / Instances of the `User` and `Unit` classes both belong to the same level of array in the `Room` class. Ideally, the `units` array should be under `User` class for easy access. However, having it on the `Room` class allows us to apply quick fixes for user-disconnection scenarios. e.g. Transfer the `userId` attribute of the `Unit` class to the room AI, or to another player present in the room.
