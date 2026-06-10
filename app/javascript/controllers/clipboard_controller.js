import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  copy() {
    navigator.clipboard.writeText(this.textValue).then(() => {
      const orig = this.element.textContent
      this.element.textContent = "Copiado!"
      setTimeout(() => { this.element.textContent = orig }, 1500)
    })
  }
}
