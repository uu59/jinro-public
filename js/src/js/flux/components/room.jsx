import React from "react"
import ReactDOM from "react-dom"
import MeStore from "../stores/me.js"
import RoomStore from "../stores/room.js"
import RoomActions from "../actions/room.js"
import connectToStores from 'alt-utils/lib/connectToStores';
import RoomMembers from "./room_members.jsx"
import RoomRoleList from "./room_role_list.jsx"
import RoomInformation from "./room_information.jsx"
import RoomLogs from "./room_logs.jsx"
import NotFound from "./not_found.jsx"
import Timer from "./timer.jsx"
import FancyTextarea from "./fancy_textarea.jsx"
import VoteBox from "./vote_box.jsx"
import API from "../../api.js"
import { Link } from 'react-router'
import Waypoint from "react-waypoint"
import _ from "lodash"

export default connectToStores(
  class Room extends React.Component {
    static getStores(props) {
      return [RoomStore, MeStore]
    }
    
    static getPropsFromStores(props, context) {
      return props.ssr ?
        props
        : (
          Object.assign(
            MeStore.getState(),
            RoomStore.getState()
          )
        )
    }

    constructor(props) {
      super(props)
    }

    componentDidMount() {
      const props = this.props

      if(props.ssr) { return }

      if(props.room.archived) {
        this.gotoArchive(this.props)
        return
      }

      if(!props.isLoading){
        RoomActions.enterRoom(props.params.id)
        if(location.hash.length == 0) {
          this.scrolledToEnd = true
        }
      }
    }

    gotoArchive(props) {
      requestAnimationFrame(() => {
        props.history.replace(`/rooms/${props.params.id}/archive`)
        RoomActions.leaveRoom()
      })
    }

    componentWillReceiveProps(nextProps) {
      if(nextProps.room.archived) {
        this.gotoArchive(nextProps)
        return
      }
    }

    componentWillUnmount() {
      RoomActions.leaveRoom()
    }

    onSubmitChat(e) {
      e.preventDefault()
      this.postChat(e.target.value)
    }

    postChat(message) {
      if(message.length === 0) { return }

      // Decide before DOM updated
      const scrollAfterPost = this.scrolledToEnd

      API.roomMessagesPost(this.props.params.id, message).catch((e) => {
        console.error(e.res.body.error)
      }).then((response) => {
        if(scrollAfterPost) {
          this.scrollToLastMessage()
        }
      }).catch((e) => {
        console.error(e)
      })
    }

    handleBottomEnter(ev) {
      // 遷移直後にnullが来ることがあるので無視
      if(ev) {
        this.scrolledToEnd = true
      }
    }

    handleBottomLeave(ev) {
      if(ev) {
        this.scrolledToEnd = false
      }
    }

    handleFormSubmit(ev) {
      console.log("handleFormSubmit", ev, ev.target.value)
    }

    onClickReply(log, ev) {
      console.log("onClickReply", arguments, this.refs.fancy)
      this.refs.fancy.handleReply.call(this.refs.fancy, ev, log)
    }

    scrollToLastMessage() {
      if(this.props.ssr) { return }

      requestAnimationFrame(() => {
        const box = ReactDOM.findDOMNode(this.refs.messageBox)
        if(box) {
          box.scrollTop = box.scrollHeight
        }
      })
    }

    render() {
      if(this.props.notfound) {
        return <NotFound {...this.props} />
      }

      if(this.scrolledToEnd) {
        this.scrollToLastMessage()
      }
      return <div className="room">
        <div className="room__body">
          <div className="room__body__sidebar">
            <RoomMembers room={this.props.room} members={this.props.members} />
            <RoomRoleList {...this.props} />
          </div>
          <div className="room__body__chat">
            <RoomInformation errors={this.props.errors} room={this.props.room} />
            <div ref="messageBox" className="room__body__chat__messages">
              <RoomLogs
                onClickReply={this.onClickReply.bind(this)}
                {...this.props}
              />
              <Waypoint
                onEnter={this.handleBottomEnter.bind(this)}
                onLeave={this.handleBottomLeave.bind(this)}
              />
            </div>
            {!this.props.ssr && <VoteBox room={this.props.room} members={this.props.members} />}
            {!this.props.ssr && <Timer to={this.props.room.frozenAt} /> }
            {!this.props.ssr &&
            <form className="room__body__chat__form chatform" onSubmit={this.onSubmitChat.bind(this)}>
              <FancyTextarea ref="fancy" disabled={this.props.room.frozenChat} className="chatform__text" onSubmit={this.onSubmitChat.bind(this)} {...this.props} />
            </form>
            }
          </div>
        </div>
      </div>
    }

  }
)
