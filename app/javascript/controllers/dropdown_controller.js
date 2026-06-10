import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this._outsideClick = this._onOutsideClick.bind(this)
  }

  toggle() {
    this.menuTarget.classList.toggle("hidden")
    if (!this.menuTarget.classList.contains("hidden")) {
      document.addEventListener("click", this._outsideClick)
    }
  }

  hide() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this._outsideClick)
  }

  _onOutsideClick(event) {
    if (!this.element.contains(event.target)) this.hide()
  }

  disconnect() {
    document.removeEventListener("click", this._outsideClick)
  }
}
