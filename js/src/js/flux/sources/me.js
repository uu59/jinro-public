import MeActions from "../actions/me.js"
import API from "../../api.js"
import Promise from "bluebird"

export default {
  fetch() {
    return { 
      remote(state) {
        console.log("me remote")
        return API.me()
      },

      shouldFetch(state){ 
        console.log("me", state.loggedIn, state.me)
        return state.loggedIn === null
      },
      local(state) { return state },

      success: MeActions.fetchSuccess,
      loading: MeActions.fetch,
      error: MeActions.fetchFailure
    }
  }
}
