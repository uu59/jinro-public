import React from "react"
import Header from "./header.jsx"
import GlobalStreamStore from "../stores/global_stream.js"
import GlobalAction from "../actions/global.js"
import connectToStores from 'alt-utils/lib/connectToStores'
import Notification from "../components/notification.jsx"

import RoomList from "./room_list.jsx"
import Room from "./room.jsx"
import RoomArchive from "./room_archive.jsx"
import NotFound from "./not_found.jsx"


const AppRoot = connectToStores(
  class _AppRoot extends React.Component {
    static getStores(props) {
      return [GlobalStreamStore]
    }
    
    static getPropsFromStores(props, context) {
      return GlobalStreamStore.getState();
    }

    constructor(props) {
      super(props)
      requestAnimationFrame(() => {
        GlobalAction.connectSystemStream()
      })
    }

    render() {
      return (
        <div id="app">
          <Header />
          {this.props.children}
          <Notification messages={this.props.logs} />
          <div className="app__footer footer">
            <p className="footer__source">
              <a target="_blank" href="https://github.com/uu59/jinro">Source Code</a>
            </p>
          </div>
        </div>
      );
    }
  }
)

export default AppRoot
