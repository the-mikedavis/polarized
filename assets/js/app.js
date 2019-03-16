import tailcss from '../css/tail.css'
import css from "../css/app.sass"
import 'phoenix_html'

import {Player} from '../src/Player.elm'

const player = document.getElementById('player')
if (player) {
  const app = Player.embed(player, {uri: buildSocketUri()})

  window.addEventListener('load', function () {
    const videoElem = document.getElementById('theater')

    // let pastUri = "";

    // function watchVideo () {
    //   let newUri = document.getElementById('theater').firstElementChild.getAttribute('src');
    //   if (newUri != pastUri) {
    //     videoElem.load();
    //     if (newUri != "")
    //       videoElem.play();
    //   }
    //   pastUri = newUri;

    //   setTimeout(watchVideo, 1000);
    // }

    // setTimeout(watchVideo, 1000);

    app.ports.playVideo.subscribe(function (uri) {
      let videoElem = document.getElementById('theater');
      setTimeout(() => {
        videoElem.load();
        videoElem.play();
      }, 100);
    });

    // var observer = new MutationObserver(function (m) {
    //   console.log(m)
    // });

    // observer.observe(videoElem, {attributes: true})

    videoElem.addEventListener('ended', function () {
      app.ports.videoEnded.send(true);
    });
  });
}

function buildSocketUri() {
  const protocol = location.protocol == 'https:' ? 'wss://' : 'ws://'
  return protocol + window.location.host + '/socket/websocket'
}
