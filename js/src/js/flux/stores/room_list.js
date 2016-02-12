import alt from '../alt'
import RoomListActions from "../actions/room_list.js"

export default alt.createStore(class RoomListStore {
  constructor() {
    this.state = {
      rooms: {
        active: [],
        archived: []
      }
    }

    this.bindActions(RoomListActions)
  }

  onFetchList(rooms) {
    this.setState({rooms})
  }
})
