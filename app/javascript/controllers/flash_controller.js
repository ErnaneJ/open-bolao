import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._timeout = setTimeout(() => this._dismiss(), 4000)
  }

  dismiss() {
    clearTimeout(this._timeout)
    this._dismiss()
  }

  _dismiss() {
    this.element.style.transition = "opacity 0.3s ease"
    this.element.style.opacity = "0"
    setTimeout(() => this.element.remove(), 300)
  }

  disconnect() {
    clearTimeout(this._timeout)
  }
}
