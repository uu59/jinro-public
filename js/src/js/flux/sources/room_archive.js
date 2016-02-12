import RoomActions from "../actions/room.js"
import API from "../../api.js"

export default {
  fetch() {
    return { 
      remote(state, id) {
        return API.roomArchive(id)
      },

      shouldFetch(state){ 
        return state.html === ""
      },
      local(state) { return state },

      success: RoomActions.fetchArchiveSuccess,
      loading: RoomActions.fetchArchive,
      error:   RoomActions.fetchArchiveFailure
    }
  }
}
