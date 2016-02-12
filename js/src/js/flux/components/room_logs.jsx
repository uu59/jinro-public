import React from "react"
import _ from "lodash"

export default class RoomLogs extends React.Component {
  render() {
    const showReply = !this.props.ssr && this.props.loggedIn
    const showAnchor = this.props.ssr

    return <ul className="messages">
      {_(this.props.chatLogs || []).sortBy("id").map((log) => {
        const sceneClass = log.scene ? `--${log.scene}` : ""
        const sideClass = log.role && log.role.side && `side--${log.role.side}`

        return <li id={log.anchor} key={log.id} className={`messages__message${sceneClass} message author--${log.from.name} ${log.sender_type} ${sideClass}`}>
          <img className="message__image" src={log.from.image} alt="" title={log.from.name} />

          <div className="message__content">
            <p className="message__content__head">
              <strong className="message__content__head__name">
                {log.sender_type == "ghost" &&
                  `(亡霊) `
                }
                {log.role && log.role.short_name &&
                  `[${log.role.short_name || ""}] `
                }
                {log.from.name}
                &nbsp;
              </strong>
              <span className="message__content__head__timestamp">
                {log.time}
              </span>
              <span className="message__content__head__actions actions">
                {showAnchor &&
                <a title="リンク" href={`#${log.anchor}`} className="actions__anchor">
                  <i className="fa fa-chain" />
                </a>
                }
                {showReply &&
                <a title="リプライ" className="actions__reply" onClick={this.props.onClickReply.bind(this, log)}>
                  <i className="fa fa-reply" />
                </a>
                }
              </span>
            </p>
            <span className="message__content__body">{log.body}</span>
          </div>
          <p className="message__body">
          </p>
          <p className="message__foot">
          </p>
        </li>
      }).value()}
    </ul>
  }
}
