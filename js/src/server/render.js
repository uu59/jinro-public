global.addEventListener = () => {}
global.WebSocket = class {
  onopen() {}
  onclose() {}
  onerror() {}
  onmessage() {}
}

const ROOT = process.cwd() // "#{App.root}/js"

import fs from "fs"
import http from "http"
import React from "react"
import ReactDOMServer from "react-dom/server"

const roomId = process.argv[2]

const App = React.createFactory(require(ROOT + '/src/js/flux/components/room.jsx').default)
const json = fs.readFileSync(`${ROOT}/archive/${roomId}.json`)
const props = Object.assign(
  {
    params: {
      id: roomId
    },
    ssr: true,
    room: {},
    members: [],
    chatLogs: [],
    errors: []
  },
  JSON.parse(json) // room, members, chatLogs
)

function render(props) {
  const html = ReactDOMServer.renderToStaticMarkup(
    React.DOM.div({style: {display: "flex", flex: 1},  dangerouslySetInnerHTML: {__html:
      ReactDOMServer.renderToString(App(props))
    }})
  )
  return Promise.resolve(html)
}

render(props).then(html => {
  fs.writeFileSync(`${ROOT}/archive/${props.params.id}.html`, html)
}).catch((e) => { console.loconsole.error(e) })
