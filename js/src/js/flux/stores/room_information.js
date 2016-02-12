import alt from '../alt'
import RoomActions from "../actions/room.js"

const RoomInformationStore = alt.createStore(class Room {
  constructor() {
    this.state = {
      scene: null
    }

    this.bindActions(RoomActions)
    console.log(RoomActions)
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

  onChangedScene() {
    console.log("onChangedScene")
    this.resetState()
  }

  onLeaveRoom() {
    this.resetState()
  }

  resetState() {
    this.setState({
      rooms: {},
      members: [],
      chatLogs: []
    })
  }
})

export default RoomStore
