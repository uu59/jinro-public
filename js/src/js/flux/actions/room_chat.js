import alt from '../alt'

export default alt.createActions(class RoomChatActions{
  constructor() {
    this.generateActions(
      "join", "leave", "connect",
      "fetchSuccess", "fetch", "fetchChannelSuccess",
      "fetchMembersStart", "fetchMembersSuccess", "fetchMembersFailure"
    )
  }

})
