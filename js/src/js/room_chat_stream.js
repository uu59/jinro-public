import Stream from "./stream.js"

export default class RoomChatStream extends Stream {
  constructor(channel) {
    super()
    this.channel = channel
    this.lastId = 0

    this.on('message', (ev) => {
      const msg = JSON.parse(ev.data)
      switch(msg.event || "") {
        case "":
          this.lastId = Math.max(this.lastId, msg.id)
          this.emit('event:message', msg)
          break;
        case "batchLogs":
          const maxId = _(msg.logs).map("id").max()
          this.lastId = Math.max(this.lastId, maxId)
          this.emit('event:message', msg.logs)
          break;
        default:
          this.emit(`event:${msg.event}`, msg)
          break;
      }
    })

    this.connect()

    this.on('conn:firstOpen', (ev) => {
      this.recent(0)
    })
    this.on('conn:reconnected', (ev) => {
      this.resume(this.lastId)
    })
  }

  recent(count) {
    this.command({
      command: "recent",
      count: count
    })
  }

  moreLogs(maxId, count = 50) {
    this.command({
      command: "moreLogs",
      maxId: maxId,
      count: count
    })
  }

  resume(since, count) {
    this.command({
      command: "resume",
      since: since,
      count: count
    })
  }
}
