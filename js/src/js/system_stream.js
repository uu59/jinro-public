import Stream from "./stream.js"

export default class SystemStream extends Stream {
  constructor(channel) {
    super()
    this.channel = channel

    this.on('message', (ev) => {
      const msg = JSON.parse(ev.data)
      this.emit('event:message', msg)
    })
    this.connect()
  }
}
