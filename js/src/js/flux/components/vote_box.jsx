import React from "react"
import connectToStores from 'alt-utils/lib/connectToStores';
import RoomActions from "../actions/room.js"
import MeStore from "../stores/me.js"
import _ from "lodash"

export default connectToStores(class VoteBox extends React.Component {
  static getStores(props) {
    return [MeStore]
  }
  
  static getPropsFromStores(props, context) {
    return MeStore.getState();
  }

  constructor(props) {
    super(props)
  }

  handleOnClick(target, ev) {
    // TODO: error handling
    console.log("handleOnClick", arguments, this.props)
    if(confirm(`ターゲット：${target.user.name}\n(選択したあとは取り消せません)`)) {
      RoomActions.vote(this.props.room.id, target.id)
    }
  }

  render() {
    const alives = _.filter(this.props.members, m => m.alive)
    const targets = _.filter(alives, m => m.user_id !== this.props.me.id)
    const voteRequired = this.props.room.voteRequired
    const votedTo = this.props.room.votedTo
    let box = null

    if(!voteRequired) {
      box = <p></p>
    } else {
      if(votedTo) {
        box = <p className="vote_box__targets--selected">
          <span className="vote_box__targets__head">
            選択済み
            <i className="fa fa-check" />
          </span>
          <span className="vote_box__targets__target">
            <img src={votedTo.image} />
            {votedTo.name}
          </span>
        </p>
      } else {
        console.log(targets)
        box = <div className="vote_box__targets">
            <span className="vote_box__targets__head">
              えらんで
            </span>
            {targets.map((m) => {
              return <p className="vote_box__targets__target" key={m.id} onClick={this.handleOnClick.bind(this, m)}>
                <img src={m.user.image} alt={m.user.name} />
                {m.user.name}
              </p>
            })}
          </div>
      }
    }
    return <div className="vote_box">
      {box}
    </div>
  }
})
