import alt from '../alt'
import RoomArchiveSource from "../sources/room_archive.js"
import RoomActions from "../actions/room.js"

const RoomArchiveStore = alt.createStore(class _RoomArchiveStore{
  constructor() {
    this.state = {
      html: "",
    }

    this.registerAsync(RoomArchiveSource)
    this.bindActions(RoomActions)
  }

  onFetchArchive(id){
    this.setState({html: ""})
  }

  onDestroyArchiveCache() {
    this.setState({html: ""})
  }

  onFetchArchiveSuccess(html) {
    this.setState({html})
  }
})

export default RoomArchiveStore
