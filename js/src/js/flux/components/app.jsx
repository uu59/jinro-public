import React from "react"
import { Router, Route, IndexRoute, Link } from 'react-router'
import createBrowserHistory from 'history/lib/createBrowserHistory'
const history = createBrowserHistory()

import AppRoot from "./app_root.jsx"
import RoomList from "./room_list.jsx"
import Room from "./room.jsx"
import RoomArchive from "./room_archive.jsx"
import NotFound from "./not_found.jsx"

class App extends React.Component {
  render() {
    return <Router history={history}>
      <Route path="/" component={AppRoot}>
        <IndexRoute component={RoomList} />
        <Route path="rooms/:id" component={Room} />
        <Route path="rooms/:id/archive" component={RoomArchive} />
        <Route path="*" component={NotFound} />
      </Route>
    </Router>
  }
}

export default App
