import React from "react"
import connectToStores from 'alt-utils/lib/connectToStores';
import API from "../../api.js"

export default class RoomInformation extends React.Component {
  constructor(props) {
    super(props)
  }

  render() {
    return <div className="room_information">
      {this.props.room.personalInfo}
      {this.props.errors.length > 0 && 
        <div className="room_information__errors errors">
          {this.props.errors.map((e, i) => {
            return <p className="errors__error" key={i}>{e}</p>
          })}
        </div>
      }
    </div>
  }
}
