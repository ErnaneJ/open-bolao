import { Controller } from "@hotwired/stimulus"

// Sliding drawer — all transform/visibility managed via inline styles
// so it works regardless of whether Tailwind CSS has been rebuilt.
export default class extends Controller {
  static targets = ["panel", "overlay", "frame"]

  connect() {
    const p = this.panelTarget
    // Set initial hidden state without transition (no flash of animation)
    p.style.transform = "translateX(100%)"
    p.style.visibility = "hidden"
    // Add transition on next frame so initial positioning doesn't animate
    requestAnimationFrame(() => {
      p.style.transition = "transform 0.3s ease"
    })
  }

  open(event) {
    event.preventDefault()
    const url = event.params.url || event.currentTarget.href
    if (url && this.hasFrameTarget) {
      this.frameTarget.src = url
    }
    const p = this.panelTarget
    p.style.visibility = "visible"
    p.style.transform = "translateX(0)"
    if (this.hasOverlayTarget) {
      this.overlayTarget.style.display = "block"
    }
    document.body.style.overflow = "hidden"
  }

  close() {
    const p = this.panelTarget
    p.style.transform = "translateX(100%)"
    if (this.hasOverlayTarget) {
      this.overlayTarget.style.display = "none"
    }
    document.body.style.overflow = ""
    // Hide after transition completes, then reset frame
    setTimeout(() => {
      p.style.visibility = "hidden"
      if (this.hasFrameTarget) this.frameTarget.removeAttribute("src")
    }, 300)
  }

  keydown(event) {
    if (event.key === "Escape") this.close()
  }
}
