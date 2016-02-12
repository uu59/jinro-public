import _ from "lodash"
import Promise from "bluebird"
import fs from "fs"
import path from "path"
import redis from "redis"
import RedisSubPool from "./redis_sub_pool.js"


export default class Redis {
  constructor(channel) {
    this.channel = channel
    RedisSubPool.connect(this.channel)
    //this.client = redis.createClient()
    this.listeners = []
  }

  addListener(out) {
    this.listeners.push(out)
  }

  removeListener(out) {
    _.remove(this.listeners, (listener) => { return listener == out })
    RedisSubPool.emit("disconnected", this.channel)
  }

  watch() {
    RedisSubPool.on(`message:${this.channel}`, (channel, message) => {
      this.broadcast(message)
    })
    RedisSubPool.emit("connected", this.channel)
    // this.client.on("message", (channel, message) => {
    //   this.broadcast(message)
    // })
    // this.client.subscribe(this.channel)
  }

  broadcast(msg) {
    let data = (typeof msg === "string") ? msg : JSON.stringify(msg)

    this.listeners.forEach((listener) => {
      listener.sendUTF(data)
    });
  }

  redis() {
    const client = redis.createClient({parser: "hiredis"})
    setTimeout(() => {
      client.end(true)
    }, 5000)
    return client;
  }

  resume(from) {
    // { [Error: ERR only (P)SUBSCRIBE / (P)UNSUBSCRIBE / PING / QUIT allowed in this context] command: 'LRANGE', code: 'ERR' }
    // already this.client is subscribing
    //const client = redis.createClient()
    this.redis().lrange(this.channel, from, -1, (err, values) => {
      if(err) { console.error(err) }
      if(!values) { return }

      values.forEach((msg) => {
        this.broadcast(msg)
      })
    })
  }

  recent(count) {
    this.redis().lrange(this.channel, -1 * count, -1, (err, values) => {
      if(err) { console.error(err) }
      let messages = []
      values.forEach((msg) => {
        messages.push(JSON.parse(msg))
      })
      this.broadcast({event: "batchLogs", logs: messages})
    })
  }
}
