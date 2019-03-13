import tailcss from '../css/tail.css'
import css from "../css/app.sass"
import 'phoenix_html'

import {Player} from '../src/Player.elm'

const player = document.getElementById('player')
if (player)
  Player.embed(player, {uri: buildSocketUri()})

function buildSocketUri() {
  const protocol = location.protocol == 'https:' ? 'wss://' : 'ws://'
  return protocol + window.location.host + '/socket/websocket'
}
