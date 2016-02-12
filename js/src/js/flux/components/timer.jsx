import React from "react"

export default class Timer extends React.Component {
  constructor(props) {
    super(props)
    this.state = { }
  }

  calcRemainSeconds() {
    const to = (new Date(this.props.to)).getTime()
    return (to - Date.now()) / 1000
  }

  componentDidMount() {
    this.timer = setInterval(() => {
      let remain = this.calcRemainSeconds()
      if(remain <= 0 ) {
        remain = 0
      }

      this.setState({
        remain: remain
      })
    }, 1000)
  }

  componentWillUnmount() {
    this.clearTimer()
  }

  clearTimer() {
    clearInterval(this.timer)
  }

  render() {
    return <div className="timer">
      {this.props.to && !isNaN(this.state.remain) && this.state.remain > 0 ?
        `残り ${Math.floor(this.state.remain)} 秒`
        : ""
      }
      <span data-dummy={this.props.to} />
    </div>
  }
}
