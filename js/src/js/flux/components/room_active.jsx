import React from "react"
import API from "../../api.js"
import RoomArchiveStore from "../stores/room_archive.js"
import RoomAction from "../actions/room.js"
import connectToStores from 'alt-utils/lib/connectToStores'

const RoomArchive = connectToStores(
  class _RoomArchive extends React.Component {
    static getStores(props) {
      return [RoomArchiveStore]
    }
    
    static getPropsFromStores(props, context) {
      return RoomArchiveStore.getState();
    }

    constructor(props) {
      console.log("arch")
      super(props)
      RoomArchiveStore.fetch(this.props.params.id)
    }

    componentWillUnmount() {
      RoomAction.destroyArchiveCache()
    }

    render() {
      const style = {
        display: "flex",
        flex: 1
      }
      return <div style={style} dangerouslySetInnerHTML={{__html: this.props.html}} />
    }
  }
)
export default RoomArchive
