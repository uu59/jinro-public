import RoomActions from "../actions/room.js"
import API from "../../api.js"

export default {
  fetch(id) {
    return { 
      remote(state, id) {
        return API.room(id)
      },

      shouldFetch(state, id){ 
        return !state.room.id
      },
      local(state, id) { return state.rooms[id] },

      success: RoomActions.fetchSuccess,
      loading: RoomActions.fetch,
      error:   RoomActions.fetchFailure
    }
  }
}
