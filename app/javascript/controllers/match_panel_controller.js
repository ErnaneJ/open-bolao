import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "frame", "overlay"]

  connect() {
    this.panelTarget.style.transform = "translateY(100%)"
  }

  open(event) {
    const url = event.params.url
    if (!url) return
    this.frameTarget.src = url
    this.panelTarget.style.transform = "translateY(0)"
    if (this.hasOverlayTarget) this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  stop(event) {
    event.stopPropagation()
  }

  close() {
    this.panelTarget.style.transform = "translateY(100%)"
    if (this.hasOverlayTarget) this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }
}
