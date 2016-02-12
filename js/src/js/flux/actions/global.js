import alt from '../alt'
import SystemStream from "../../system_stream.js"
import RoomListActions from "../actions/room_list.js"

const GlobalActions = alt.createActions(
  class {
    constructor() {
      global.addEventListener('keydown', (ev) => {
        if(ev.keyCode === 9){
          ev.preventDefault()
          const tx = document.querySelector('textarea')
          if(!tx) { return ; }
          if(tx === document.activeElement) {
            tx.blur()
          } else {
            tx.focus()
          }
        }
      })

      this.generateActions(
        "connectSystemStream",
        "receiveSystemMessage"
      )
      this.stream = new SystemStream("global")

      this.stream.on('conn:firstOpen', (ev) => {
        GlobalActions.connectSystemStream(ev)
      })

      this.stream.on('message', (ev) => {
        const msg = JSON.parse(ev.data)
        switch(msg.event) {
          case "rooms:created":
            RoomListActions.fetchList()
            break;
          case "rooms:members:updated":
            RoomListActions.fetchList()
            break;
        }
        // GlobalActions.receiveSystemMessage()
      })
    }
  }
)

export default GlobalActions
