import EventEmitter from 'events'
import redis from "redis"

const connections = {}
const listners = {}

class RedisSubPool extends EventEmitter {
  constructor() {
    super()

    this.on("connected", (channelId) => {
      this.incrementListener(channelId)
    })

    this.on("disconnected", (channelId) => {
      this.decrementListener(channelId)
    })
  }

  connect(channelId) {
    if(connections[channelId]) {
      return
    }

    this.validateChannelId(channelId).then(() => {
      console.log("then")
      const client = redis.createClient({parser: "hiredis"})
      client.on("message", (...args) => {
        this.emit(`message:${channelId}`, ...args)
      })
      client.subscribe(channelId)
      connections[channelId] = client
    }).catch((e) => {
      console.error(e)
    })
  }

  validateChannelId(id) {
    const client = redis.createClient({parser: "hiredis"})
    return new Promise((resolve, reject) => {
      client.get("active_pub_channels", (err, values) => {
        client.end(true)

        if(err) {
          reject(err)
        } else {
          if (!values || values.length === 0) {
            reject("valid channels are null")
            return
          }

          const ret = values.indexOf(id) !== -1
          if(ret) {
            resolve()
          } else {
            reject(new Error(`invalid channel id given: ${id}`))
          }
        }
      })
    })
  }

  incrementListener(id) {
    listners[id] = listners[id] || 0
    listners[id]++
  }

  decrementListener(id) {
    if(!listners[id]) { return }

    listners[id]--
    if(listners[id] <= 0 && connections[id]) {
      connections[id].end(true)
      connections[id] = null
    }
  }
}

export default new RedisSubPool
