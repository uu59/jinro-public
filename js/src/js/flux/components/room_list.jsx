import React from "react"
import MeStore from "../stores/me.js"
import RoomListStore from "../stores/room_list.js"
import connectToStores from 'alt-utils/lib/connectToStores';
import RoomListActions from "../actions/room_list.js"
import { Link } from 'react-router'
import API from "../../api.js"

export default connectToStores(
  class RoomList extends React.Component {
    static getStores(props) {
      return [RoomListStore, MeStore]
    }
    
    static getPropsFromStores(props, context) {
      return Object.assign(
        MeStore.getState(),
        RoomListStore.getState()
      )
    }

    constructor(props) {
      RoomListActions.fetchList()
      super(props)
      this.state = {
        candidates: _([
          "チェダー", "エダム", "ゴーダ", "カマンベール", "グリュイエール",
          "ロックフォール", "ゴルゴンゾーラ"
        ])
      }
    }

    onSubmit(e) {
      e.preventDefault()
      let q = {
        name: this.refs.name.value
      }
      RoomListActions.create(q).then((response) => {
        this.props.history.push(`/rooms/${response.body.id}`)
      })
    }

    renderLink(room, archived = false) {
      return <span key={room.id} className="link-wrapper">
        <Link to={`/rooms/${room.id}${archived ? "/archive": ""}`}>{room.name}村</Link>
      </span>
    }

    render() {
      const name = this.state.candidates.sample()
      return <div className="room-list">
        <div className="room-list__active">
          <h1>アクティブ</h1>
          {this.props.loggedIn &&
            <form onSubmit={this.onSubmit.bind(this)}>
              <input type="text" ref="name" placeholder={`例：${name}`} />
              <input type="submit" value="村を作成" />
            </form>
          }
          {this.props.rooms.active.map((room) => {
            return <span key={room.id} className="link-wrapper">
              <Link to={`/rooms/${room.id}`}>{room.name}村</Link>
              <p className="room-list__active__member">
              {room.users.map((u) => {
                return <span key={u.id}>
                  <img src={u.image} alt={u.name} title={u.name} /><br />
                </span>
              })}
              </p>
            </span>
          })}
        </div>
        <div className="room-list__archived">
          <h1>過去ログ</h1>
          {this.props.rooms.archived.map((room) => {
            return <span key={room.id} className="link-wrapper">
              <Link to={`/rooms/${room.id}/archive`}>{room.name}村{`(${room.member_count}人)`}</Link>
            </span>
          })}
        </div>
      </div>
    }
  }
)
