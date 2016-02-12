import React from "react"
import connectToStores from 'alt-utils/lib/connectToStores';

import RoomActions from "../actions/room.js"

export default 
  class RoomRoleList extends React.Component {
    constructor(props) {
      super(props)
    }

    render() {
      return <div className="room-role-list">
        <h1 className="room-role-list__pattern">
          {this.props.room.rolePattern && `配役 (${this.props.room.rolePattern})`}
        </h1>
        <table className="room-role-list__roles">
        {Object.keys(this.props.room.roles || {}).map((role) => {
          let count = this.props.room.roles[role]
          return <tr key={role}>
            <td>{role}</td>
            <td>{count}</td>
          </tr>
        })}
        </table>
      </div>
    }
  }
