import alt from '../alt'
import API from "../../api.js"

export default alt.createActions(class RoomListActions{
  constructor() {
    // this.generateActions("fetchSuccess", "fetch")
  }

  fetchList() {
    return async (dispatch) => {
      const response = await API.rooms()
      dispatch(response.body)
    }
  }

  create(room) {
    return (dispatch) => {
      dispatch(room)
      return API.roomsCreate(room)
      // ↓global stream do this
      // this.fetchList()
    }
  }
})
