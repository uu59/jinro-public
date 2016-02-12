import alt from '../alt'
import RoomChatSource from "../sources/room_chat.js"
import RoomChatActions from "../actions/room_chat.js"

export default alt.createStore(class RoomMembersStore {
  constructor() {
    this.state = {
      members: []
    }

    this.bindActions(RoomChatActions)
    this.exportAsync(RoomChatSource)
  }

  fetchMembersSuccess(response){
    this.setState(Object.assign(
      this.state,
      {members: response.body}
    ))
  }
})
