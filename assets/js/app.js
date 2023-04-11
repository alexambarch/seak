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
    /**
     * Send events to the LiveView when the video state changes.
     * */

    let phxNotify = event => {
      console.log(`${event.type}_video: ${this.el.currentTime}`)
      this.pushEvent(
        `${event.type}_video`, this.el.currentTime
      )
    };

    ["play", "seeked", "pause", "waiting"].forEach(
      event => this.el.addEventListener(event, phxNotify)
    )

    /**
     * Handle events sent from the LiveView.
     *
     * In both play and pause events, we want to ensure that a programmatic play
     * and pause do not cause a new event to be broadcast, as this would cause
     * an endless loop of events being sent and then attempting to process them.
     * */
    this.handleEvent("startPlaying", payload => {
      let { current_time } = payload
      console.log(`start at ${current_time}`)

      this.el.removeEventListener("play", phxNotify)
      this.el.removeEventListener("seeked", phxNotify)

      this.el.currentTime = parseFloat(current_time)
      this.el.play()

      setTimeout(() => {
        this.el.addEventListener("play", phxNotify)
        this.el.addEventListener("seeked", phxNotify)
      }, 0)
    })

    this.handleEvent("stopPlaying", payload => {
      let { current_time } = payload
      console.log(`stop at ${current_time}`)

      this.el.removeEventListener("pause", phxNotify)
      this.el.removeEventListener("seeked", phxNotify)

      this.el.pause()
      this.el.currentTime = parseFloat(current_time)

      setTimeout(() => {
        this.el.addEventListener("pause", phxNotify)
        this.el.addEventListener("seeked", phxNotify)
      }, 0)
    })

    this.handleEvent("seek", payload => {
      let { current_time } = payload
      this.el.removeEventListener("seeked", phxNotify)

      this.el.currentTime = current_time

      setTimeout(() => {
        this.el.addEventListener("seeked", phxNotify)
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
