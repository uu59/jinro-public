import React from "react"
import connectToStores from 'alt-utils/lib/connectToStores';
import MeStore from "../stores/me.js"

import RoomActions from "../actions/room.js"

import API from "../../api.js"
import _ from "lodash"

export default connectToStores(
  class RoomMembers extends React.Component {
    static getStores(props) {
      return [MeStore]
    }

    static getPropsFromStores(props, context) {
      return MeStore.getState()
    }

    constructor(props) {
      super(props)
    }

    handleOnJoin(ev) {
      API.roomJoin(this.props.room.id)
    }

    handleOnLeave(ev) {
      API.roomLeave(this.props.room.id)
    }

    onClickStart(ev) {
      RoomActions.startGame(this.props.room.id)
    }

    render() {
      const memberIds = _.map(this.props.members, m => m.user.id)
      const isAlreadyJoined = _.includes(memberIds, this.props.me.id)
      const isReadyToStart = this.props.room.isReady
      const canStart = this.props.room && this.props.room.state == "prologue" && isAlreadyJoined && isReadyToStart
      const joinOrLeave = (
        this.props.loggedIn ? 
          (isAlreadyJoined ? 
            <input type="submit" value="leave" onClick={this.handleOnLeave.bind(this)} />
            : <input type="submit" value="join" onClick={this.handleOnJoin.bind(this)} />
          )
          : ""
      )
      const icon = {
        "night": "fa-moon-o",
        "evening": "fa-sun-o",
        "epilogue": "fa-coffee",
        "fin": "fa-thumb-tack"
      }[this.props.room.scene && this.props.room.scene.type]

      return <div className="members">
        <div className="members__header">
          <span className="members__header__joinleave">
            <i className={`fa ${icon}`} />
            {this.props.room && this.props.room.state == "prologue" && joinOrLeave}
          </span>
          <span className="members__header__count">
            参加者 {this.props.members.length} 人
          </span>
        </div>
        <ul className="members__names">
          {this.props.members.map((member) => {
            const className = member.alive ? "" : "--died"
            return <li key={member.id} className={`member members__names__member${className}`}>
              <p className="member__image">
                <img src={member.user.image} alt={member.user.name} />
              </p>
              <p className="member__name">
                {member.user.name}
                <strong className="member__names__role">{member.role ? `(${member.role})` : ""}</strong>
              </p>
            </li>
            })}
        </ul>
        {canStart &&
          <span className="members__start">
            <input type="submit" value="ゲーム開始" onClick={this.onClickStart.bind(this)} />
          </span>
        }
      </div>
    }
  }
)
