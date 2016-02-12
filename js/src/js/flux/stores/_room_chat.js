import alt from '../alt'
import RoomChatActions from "../actions/room_chat.js"
import RoomChatSource from "../sources/room_chat.js"
import RoomChatStream from "../../room_chat_stream.js"

export default alt.createStore(class RoomChatStore {
  constructor() {
    this.state = {
      channel: null,
      chatLogs: []
    }
    this.bindListeners({
      handleJoin: RoomChatActions.JOIN,
      handleConnect: RoomChatActions.CONNECT,
      handleLeave: RoomChatActions.LEAVE
    })
    this.bindActions(RoomChatActions)
    this.registerAsync(RoomChatSource)
  }

  handleLeave() {
    console.log("handleLeave")
    if(this.stream) {
      this.stream.destroy()
    }
    this.setState({
      channel: null,
      logs: []
    })
  }

  fetchChannelSuccess(response) {
    this.setState(Object.assign(this.state, {
      channel: response.body
    }))
  }

  onReceiveChatStream(msg) {
    const logs = this.state.logs;
    logs.push(msg)
    this.setState({
      logs: logs
    })
  }

  onFetchSuccess(response){
    this.setState({
      logs: response.body
    })
  }
})
