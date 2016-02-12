import {EventEmitter} from "events"

export default class Stream extends EventEmitter {
  constructor(channel) {
    super()
    this.channel = channel
  }

  command(payload) {
    this.ws.send(JSON.stringify(payload))
  }

  destroy() {
    this.removeAllListeners()

    if(this.ws) {
      this.ws.close()
    }
    this.ws = null
  }

  reconnect() {
    setTimeout( () => {
      this.emit('conn:reconnecting', this.retry)
      this.connect(true)
    }, Math.min(this.retry * 1000, 5000))
  }

  connect(reconnect = false) {
    const proto = (location.protocol === "https:") ? "wss" : "ws"
    this.ws = new WebSocket(`${proto}://${location.host}/stream/${this.channel}`, "echo-protocol")

    if(reconnect) {
      this.retry += 1
    }

    // when reconnect fail, retry with this conn:close event
    this.removeListener("conn:close", this.reconnect)
    this.on("conn:close", this.reconnect)

    this.ws.onopen = (ev) => {
      this.retry = 0
      this.emit("conn:open", ev)
      if(reconnect) {
        this.emit("conn:reconnected", ev)
      } else {
        this.emit("conn:firstOpen")
      }
    }
    this.ws.onerror = (ev) => { this.emit("conn:error", ev) }

    this.ws.onmessage = (ev) => { this.emit("message", ev) }

    this.ws.onclose = (ev) => {
      this.emit("conn:close", ev)
    }
  }
}
