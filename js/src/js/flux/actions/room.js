import alt from '../alt'

import API from "../../api.js"
import RoomChatStream from "../../room_chat_stream.js"
import SystemStream from "../../system_stream.js"
import createBrowserHistory from 'history/lib/createBrowserHistory'

const RoomActions = alt.createActions(class {
  constructor() {
    this.generateActions(
      "receiveChatMessage",
      "receiveMembers", "updatedMembers",
      "fetch", "roomFetchSuccess",
      "fetchArchive",  "fetchArchiveFailure", "destroyArchiveCache",
      "enterRoomFinished",
      "voteFailed"
    )
  }

  fetchArchiveSuccess(response) {
    return response.text
  }

  gotoArchive(roomId) {
    this.goto(`/rooms/${roomId}/archive`)
  }

  startGame(roomId) {
    return async (dispatch) => {
      dispatch()
      return API.roomStart(roomId)
    }
  }

  goto(path, replace = false) {
    const history = createBrowserHistory()
    if(replace) {
      history.replace(path)
    }else{
      history.push(path)
    }
  }

  chatFetchMore(knownMinId) {
    this.chatStream.moreLogs(knownMinId, 50)
    return knownMinId;
  }

  fetchChannelFailure(){
    console.error("fetchChannelFailure", arguments)
  }

  connectChatStream(channel) {
    this.chatStream = new RoomChatStream(channel)
    this.chatStream.on("event:message", (msg) => {
      RoomActions.receiveChatMessage(msg)
    })
    return channel
  }

  changedScene(roomId) {
    return async (dispatch) => {
      dispatch(roomId)
      await Promise.delay(2000) // room is not updated yet if too quickly fetch it
      return Promise.all([
        API.roomChannel(roomId).then(res => RoomActions.connectChatStream(res.body)),
        API.roomMembers(roomId).then(res => RoomActions.receiveMembers(res.body)),
        API.room(roomId).then(res => RoomActions.roomFetchSuccess(res))
      ])
    }
  }

  async asyncChangedScene(roomId) {
    RoomActions.changedScene(roomId)
  }

  leaveRoom() {
    // /rooms/:id -> /rooms/:id/archiveのときはこのふたつは作られない
    this.roomStream && this.roomStream.destroy()
    this.chatStream && this.chatStream.destroy()
    return "hi";
  }

  enterRoom(roomId) {
    this.roomId = roomId
    this.roomStream = new SystemStream(`room-${roomId}`)
    this.roomStream.on('event:message', (msg) => {
      switch(msg.event) {
        case "updated:members":
          API.room(this.roomId).then(res => RoomActions.roomFetchSuccess(res))
          RoomActions.receiveMembers(msg.members)
          break;

        case "scene:changed":
          RoomActions.asyncChangedScene(msg.roomId)
          break;

        case "vote:invalidated":
          API.room(this.roomId).then(res => RoomActions.roomFetchSuccess(res))
          break;

        case "room:updated":
          API.room(this.roomId).then(res => RoomActions.roomFetchSuccess(res))
          break
      }
    })

    return async (dispatch) => {
      dispatch()
      return await API.room(roomId)
        .then(res => RoomActions.roomFetchSuccess(res))
        .then(() => {
          Promise.all([
            API.roomChannel(roomId).then(res => RoomActions.connectChatStream(res.body)),
            API.roomMembers(roomId).then(res => RoomActions.receiveMembers(res.body))
          ])
        })
        .catch(res => { res.status == 404 && RoomActions.roomFetchFail() })
        .then(() => { RoomActions.enterRoomFinished() })
    }
  }

  voteSuccess(res) {
    Promise.delay(250).then(() => {
      API.room(this.roomId).then(res => RoomActions.roomFetchSuccess(res), err => { res.status == 404 && this.roomFetchFail() })
    })
    return res
  }

  roomFetchFail() {
    return 12
    // this.goto("/notfound")
  }

  async join(roomId) {
  }

  async vote(roomId, targetId) {
    API.roomVote(roomId, targetId).then(
      (res) => { RoomActions.voteSuccess(res) },
      (res) => { RoomActions.voteFailed(res) }
    )
  }
})

export default RoomActions
