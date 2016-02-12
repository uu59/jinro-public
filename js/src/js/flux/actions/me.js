import alt from '../alt'
import API from "../../api.js"

const MeActions = alt.createActions(class {
  constructor() {
    this.generateActions(
      "fetchSuccess"
    )
  }

  async fetch() {
    // TODO: fetch failure
    return await API.me().then(response => MeActions.fetchSuccess(response))
  }
})

export default MeActions
