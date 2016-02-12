import React from "react"
import MeStore from "../stores/me.js"
import connectToStores from 'alt-utils/lib/connectToStores';

import Help from "./help.jsx"

import { Link } from 'react-router'
import { browserHistory } from 'react-router'

export default connectToStores(
  class Header extends React.Component {
    static getStores(props) {
      return [MeStore]
    }
    
    static getPropsFromStores(props, context) {
      return MeStore.getState();
    }

    render() {
      let className = this.props.loggedIn 
      const roomLink = <div className="header__linktop">
        <Link to="/">jinro</Link>
      </div>

      switch(this.props.loggedIn) {
        case null:
          return <div className="app__header header">
            {roomLink}
            <Help />
          </div>
        case true:
          return <div className="app__header header--loggedin">
            {roomLink}
            <div className="header__me">
              <img src={this.props.me.image} />
              <span>{this.props.me.name}</span>
            </div>
            <Help />
          </div>
        case false:
          return <div className="app__header header--nologin">
            {roomLink}
            <a className="header__login" href="/auth/github">
              <i className="fa fa-github" />
              Signin with GitHub
            </a>
            <Help />
          </div>
      }
    }
  }
)
