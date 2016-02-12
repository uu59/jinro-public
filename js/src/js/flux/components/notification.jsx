import React from "react"
import GlobalActions from "../actions/global.js"
import connectToStores from 'alt-utils/lib/connectToStores';

export default class Notification extends React.Component {
  render() {
    return <div className="app__notifications notifications">
      {this.props.messages.map((msg) => {
        return <div key={msg.time} className="notifications__message">
          <h1 className="notifications__message__title">{msg.title}</h1>
          <p className="notifications__message__body">{msg.body}</p>
        </div>
      })}
    </div>
  }
}
