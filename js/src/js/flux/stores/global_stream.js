import alt from '../alt'
import SystemStream from "../../system_stream.js"
import GlobalActions from "../actions/global.js"

export default alt.createStore(class GlobalStreamStore {
  constructor() {
    this.state = {
      logs: []
    }

    this.bindActions(GlobalActions)
  }

  onReceiveSystemMessage(msg) {
    this.state.logs.push(msg)
    this.setState(this.state)
  }
})
