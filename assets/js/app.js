import tailcss from '../css/tail.css'
import css from "../css/app.sass"
import 'phoenix_html'

import {Player} from '../src/Player.elm'

const player = document.getElementById('player')
if (player) {
  const app = Player.embed(player, {uri: buildSocketUri()})

  window.addEventListener('load', function () {
    const videoElem = document.getElementById('theater')

    app.ports.playVideo.subscribe(function (uri) {
      if (uri != "") {
        let videoElem = document.getElementById('theater');
        setTimeout(() => {
          videoElem.load();
          videoElem.play();

          videoElem.addEventListener('ended', function () {
            app.ports.videoEnded.send(true);
          });
        }, 100);
      }
    });
  });
}

function buildSocketUri() {
  const protocol = location.protocol == 'https:' ? 'wss://' : 'ws://'
  return protocol + window.location.host + '/socket/websocket'
}
