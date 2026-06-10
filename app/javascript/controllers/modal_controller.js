import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (!event || event.target === this.dialogTarget || event.currentTarget.dataset.modalClose) {
      this.dialogTarget.close()
      document.body.style.overflow = ""
    }
  }

  // Close on backdrop click
  backdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  // Close on Escape (native dialog handles this, but ensure overflow reset)
  disconnect() {
    document.body.style.overflow = ""
  }
}
