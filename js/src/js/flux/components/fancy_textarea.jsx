import React from "react"
import ReactDOM from "react-dom"

export default class FancyTextarea extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      height: 1,
      padding: 0.5
    }
  }

  componentDidMount() {
    if(this.props.autofocus !== false) {
      this.refs.el.focus()
    }
  }

  handleInput(ev) {
    if(ev.which === 13 && !ev.shiftKey) {
      this.submit(ev)
    }
  }

  handleChange(ev) {
    this.expandIfNeeded(ev.target)
  }

  handleReply(ev, log) {
    const replyBody = `${log.from.name} [${log.time}]\n${log.body}`
    const reply = replyBody.split("\n").map(line => `> ${line}`).join("\n")
    this.refs.el.value = reply + "\n"
    this.refs.el.focus()
    this.expandIfNeeded(this.refs.el)
  }

  expandIfNeeded(target) {
    const lines = target.value.split("\n").length
    const height = Math.min(Math.max(1, lines), 6)
    const padding = height / 2
    this.setState({height, padding})
  }

  submit(ev) {
    ev.preventDefault()
    this.props.onSubmit(ev)
    ev.target.value = ""
    this.expandIfNeeded(ev.target)
  }

  render() {
    const defaultStyle = {
      resize: "none",
      borderRadius: "3px",
      height: `${this.state.height}em`,
      padding: `0.5em 0.5em ${this.state.padding}em 0.5em`,
      overflow: "auto",
      visibility: (this.props.loggedIn === null) ? "hidden" : "visible"
    }
    const style = Object.assign(defaultStyle, this.props.style || {})
    const disabled = this.props.disabled || !this.props.loggedIn
    const placeholder = disabled ? 
      (this.props.loggedIn ?
        "時間オーバーのため発言できません。投票待ちです。"
        : "ログインすると発言できます"
      ) : ""

    return <div className="fancy-textarea">
      <textarea
        onChange={this.handleChange.bind(this)}
        onKeyPress={this.handleInput.bind(this)}
        style={style}
        ref="el"
        disabled={disabled}
        placeholder={placeholder}
      />
    </div>

  }
}
