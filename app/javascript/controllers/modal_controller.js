import { Controller } from "@hotwired/stimulus"

// Native <dialog> with showModal() goes to the top layer.
// CSS centering of top-layer elements is inconsistent across browsers
// when the dialog is a descendant of a positioned/transformed ancestor.
// Inline style overrides guarantee correct centering everywhere.
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    const dialog = this.dialogTarget
    this._center(dialog)
    dialog.showModal()
    document.body.style.overflow = "hidden"
  }

  close(event) {
    if (!event || event.target === this.dialogTarget || event.currentTarget.dataset.modalClose) {
      this.dialogTarget.close()
      document.body.style.overflow = ""
    }
  }

  backdropClick(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  disconnect() {
    document.body.style.overflow = ""
  }

  _center(dialog) {
    // Force fixed centering regardless of ancestor transforms / containing blocks
    Object.assign(dialog.style, {
      position: "fixed",
      top:      "50%",
      left:     "50%",
      transform: "translate(-50%, -50%)",
      margin:   "0",
    })
  }
}
