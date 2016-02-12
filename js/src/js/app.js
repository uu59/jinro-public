import "babel-polyfill"
import Promise from "bluebird"
Promise.config({
  longStackTraces: false
})
global.Promise = Promise
// require('source-map-support').install()
// global.onunhandledrejection = function(reason, promise) {
//       window.onerror(reason.message, "", "", "", reason);
// };

import React from "react"
import ReactDOM from "react-dom"
import App from "./flux/components/app.jsx"
import init from "./init.js"
init()

ReactDOM.render(
  <App />,
  document.querySelector("#jinro")
)

