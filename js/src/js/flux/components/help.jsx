import React from "react"

export default class Help extends React.Component {
  constructor(props) {
    super(props)

    this.state = {
      closed: true
    }
  }

  handleClick(ev) {
    this.setState({
      closed: !this.state.closed
    })
  }

  handleClickContent(ev) {
    ev.stopPropagation()
  }

  renderClosed() {
    return <div className="help" onClick={this.handleClick.bind(this)}>
      <i className="fa fa-question" />
    </div>
  }

  renderOpened() {
    return <div className="help--opened" onClick={this.handleClick.bind(this)}>
      <div className="help__overlay" />
      <div className="help__content" onClick={this.handleClickContent.bind(this)}>
        <h1>ヘルプ</h1>
        <p>
          TODO
        </p>
      </div>
    </div>
  }

  render() {
    if (this.state.closed) {
      return this.renderClosed()
    } else {
      return this.renderOpened()
    }
  }
}

