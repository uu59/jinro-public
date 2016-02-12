import alt from '../alt'
import RoomActions from "../actions/room.js"

const RoomStore = alt.createStore(class Room {
  constructor() {
    this.state = this.initialState()
    console.log(this.state)

    // this.registerAsync(RoomSource)
    this.bindActions(RoomActions)
  }

  onGotoArchive() {
    this.resetState()
  }

  onReceiveChatMessage(msg) {
    const logs = _.uniqBy(this.state.chatLogs.concat(msg), "id")
    this.state.chatLogs = logs
    this.setState(this.state)
  }

  onReceiveMembers(members) {
    this.state.members = members;
    this.setState(this.state)
  }

  onChangedScene(roomId) {
    console.log("onChangedScene", roomId)
    this.resetState()
  }

  onFetch() {
    console.log("onFetch")
    this.setState(Object.assign(
      this.state,
      {isLoading: true}
    ))
  }

  onRoomFetchFail() {
    console.log("onRoomFetchFail")
    this.setState(Object.assign(
      this.state,
      {
        isLoading: false,
        notfound: true
      }
    ))
  }

  onRoomFetchSuccess(response) {
    this.setState(Object.assign(
      this.state,
      {
        room: response.body,
        notfound: false,
        isLoading: false
      }
    ))
  }

  onVoteSuccess(response) {
    this.setState(Object.assign(
      {
        errors: [],
        isLoading: false
      }
    ))
  }

  onVoteFailed(response) {
    this.setState(Object.assign(
      this.state,
      {
        errors: response.body,
        isLoading: false
      }
    ))
  }

  onEnterRoom() {
    console.log("--onEnterRoom", arguments)
    this.setState(Object.assign(
      this.state,
      {
        isLoading: true,
        notfound: false
      }
    ))
  }

  onLeaveRoom() {
    this.resetState()
  }

  resetState() {
    this.setState(this.initialState())
  }

  initialState() {
    return {
      room: {},
      members: [],
      chatLogs: [],
      errors: [],
      notfound: null,
      archived: null,
      isLoading: false
    }
  }
})

export default RoomStore
