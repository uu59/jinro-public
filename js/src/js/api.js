import request from "superagent-bluebird-promise"

const BASE = "/api/v1"

class API {
  constructor() {
    this.host = ""
  }

  get(path, params={}) {
    return request.get(`${this.host}${BASE}${path}`).query(params).promise()
  }

  post(path, params={}) {
    return request.post(`${this.host}${BASE}${path}`).send(params).promise()
  }

  del(path) {
    return request.del(`${this.host}${BASE}${path}`).promise()
  }

  put(path) {
    return request.put(`${this.host}${BASE}${path}`).promise()
  }

  me() {
    return this.get("/users/me")
  }

  rooms() {
    return this.get("/rooms")
  }

  roomsCreate(params = {}) {
    return this.post("/rooms", params)
  }

  room(id) {
    return this.get(`/rooms/${id}`)
  }

  roomMembers(id) {
    return this.get(`/rooms/${id}/members`)
  }

  roomMessagesPost(id, message) {
    return this.post(`/rooms/${id}/messages`, {message})
  }

  roomJoin(id) {
    return this.post(`/rooms/${id}/members`)
  }

  roomLeave(id) {
    return this.del(`/rooms/${id}/members`)
  }

  roomChannel(id) {
    return this.get(`/rooms/${id}/channel`)
  }

  roomVote(id, to) {
    return this.put(`/rooms/${id}/votes/${to}`)
  }

  roomArchive(id) {
    return this.get(`/rooms/${id}/archive`)
  }

  roomStart(id) {
    return this.put(`/rooms/${id}/start`)
  }

}

const api = new API()
export default api
