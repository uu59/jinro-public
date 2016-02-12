import React from "react"
import ReactDOM from "react-dom"
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
      super(props)
      RoomArchiveStore.fetch(this.props.params.id)
    }

    componentDidUpdate() {
      if(location.hash.length > 0) {
        if(this.props.html.length === 0) {
          return
        }
        requestAnimationFrame(() => {
          const anchor = location.hash.substr(1)
          this.scrollToAnchor(anchor)
        })
      }
    }

    scrollToAnchor(anchor) {
      const box = ReactDOM.findDOMNode(document.querySelector(`.room__body__chat__messages`))
      const target = ReactDOM.findDOMNode(document.querySelector(`*[id="${anchor}"]`))
      if(!box || !target) { return }

      const startPos = box.scrollTop
      const endPos = target.offsetTop
      const duration = 500
      const delta = endPos - startPos
      const startTime = Date.now()

      const easeOutExpo = (t, b, c, d) => {
        return c * ( -Math.pow( 2, -10 * t/d ) + 1 ) + b;
      }

      const easeOutQuad = (t, b, c, d) => {
        t /= d;
        return -c * t*(t-2) + b;
      }

      const easeOutCube = (t, b, c, d) => {
        t /= d;
        t--;
        return c*(t*t*t + 1) + b;
      }

      const animate = () => {
        const time = Date.now() - startTime
        const newValue = easeOutCube(time, startPos, delta, duration)
        box.scrollTop = newValue
        if(time < duration && box.scrollTop < endPos) {
          requestAnimationFrame(animate)
        }
      }
      animate()
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
