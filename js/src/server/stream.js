import {server as WebSocketServer} from "websocket"
import http from "http"
import Redis from "./redis.js"

const server = http.createServer((req, res) => {
  res.writeHead(404)
  res.end()
})
const wsServer = new WebSocketServer({
  httpServer: server,
  // You should not use autoAcceptConnections for production
  // applications, as it defeats all standard cross-origin protection
  // facilities built into the protocol and the browser.  You should
  // *always* verify the connection's origin and decide whether or not
  // to accept it.
  autoAcceptConnections: false
});


function originIsAllowed(origin) {
  // put logic here to detect whether the specified origin is allowed.
  return true;
}

class ClientCommand {
  constructor(payload) {
    this.payload = payload
  }

  getCommand() {
    this.payload.command;
  }
}

wsServer.on('request', (request) => {
  if (!originIsAllowed(request.origin)) {
    // Make sure we only accept requests from an allowed origin
    request.reject();
    console.log((new Date()) + ' Connection from origin ' + request.origin + ' rejected.');
    return;
  }

  let connection
  try {
    connection = request.accept('echo-protocol', request.origin);
  } catch(e) {
    console.error(e)
    return
  }
  console.log((new Date()) + ' Connection accepted.');

  const channel = request.resource.replace("/stream/", "")
  const watcher = new Redis(channel)
  watcher.addListener(connection)
  watcher.watch()

  connection.on('message', (msg) => {
    const payload = JSON.parse(msg.utf8Data)
    switch(payload.command) {
      case "resume":
        watcher.resume(payload.since)
        break;

      case "recent":
        watcher.recent(payload.count)
        break;

      case "moreLogs":
        watcher.moreLogs(payload.maxId, payload.count)
        break;

      default:
        console.error("Unknown command: " + JSON.stringify(payload))
        break;
    }
  })

  connection.on('close', (reasonCode, description) => {
    watcher.removeListener(connection)
    console.log((new Date()) + ' Peer ' + connection.remoteAddress + ' disconnected: ' + description);
  });
});

server.listen(3000, () => {
  console.log('WebSocket server is listening on port 3000');
});


