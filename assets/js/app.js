// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"


let Hooks = {}

Hooks.Video = {
  mounted () {
    // Update a user's presence without telling anyone else to change their video.
    let updatePresence = status => this.pushEvent("update_presence", status)

    // Send events to LiveView when the user interacts with the video.
    let phxNotify = event => this.pushEvent(`${event.type}_video`, this.el.currentTime)

    ["play", "pause", "waiting", "seeking"].forEach(
      event => this.el.addEventListener(event, phxNotify)
    )

    /**
     * Handle events sent from the LiveView.
     *
     * To ensure we do not accidentally fire new events, we need to temporarily
     * remove the event listeners and then re-add them at the end of the JS event
     * queue.
     * */
    this.handleEvent("startPlaying", payload => {
      this.el.removeEventListener("play", phxNotify)

      this.el.play()
      updatePresence("playing")

      setTimeout(() => {
        this.el.addEventListener("play", phxNotify)
      }, 0)
    })

    this.handleEvent("stopPlaying", payload => {
      this.el.removeEventListener("pause", phxNotify)

      this.el.pause()
      updatePresence("paused")

      setTimeout(() => {
        this.el.addEventListener("pause", phxNotify)
      }, 0)
    })

    this.handleEvent("seek", payload => {
      let { current_time } = payload

      this.el.removeEventListener("seeking", phxNotify)
      this.el.currentTime = current_time

      setTimeout(() => {
        this.el.addEventListener("seeking", phxNotify)
      }, 0)
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
