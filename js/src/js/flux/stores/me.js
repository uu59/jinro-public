import alt from '../alt'
import MeActions from "../actions/me.js"

const MeStore = alt.createStore(class {
  constructor() {
    this.state = {
      loggedIn: null,
      me: {}
    }

    this.bindActions(MeActions)
  }

  onFetchSuccess(response) {
    this.setState({
      me: response.body,
      loggedIn: response.body.id ? true : false
    })
  }
})

export default MeStore
