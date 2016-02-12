import RoomChatActions from "../actions/room_chat.js"
import API from "../../api.js"

export default {
  fetchChannel(roomId) {
    return {
      remote(state, id) {
        return API.roomChannel(id)
      },

      shouldFetch(state, id){ 
        return !state.channel
      },
      local(state, id) { return state.channel },

      success: RoomChatActions.fetchChannelSuccess,
      loading: RoomChatActions.fetchChannel,
      error:   RoomChatActions.fetchChannelFailure
    }
  },

  fetchMembers(roomId) {
    return {
      remote(state, id) {
        console.log("source fetchMembers")
        return API.roomMembers(id)
      },

      shouldFetch(state, id) { return true },
      local(state, id) { return },

      loading: RoomChatActions.fetchMembersStart,
      success: RoomChatActions.fetchMembersSuccess,
      error:   RoomChatActions.fetchMembersFailure
    }
  },

  resume(id) {
    return {
      remote(state, id) {
        return API.room(id)
      },

      shouldFetch(state, id){ 
        console.log("shouldFetch", state)
        return !state.rooms[id]
      },
      local(state, id) { return state.rooms[id] },

      success: RoomChatActions.fetchSuccess,
      loading: RoomChatActions.fetch,
      error:   RoomChatActions.fetchFailure
    }
  }
}
