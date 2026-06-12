import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "indicator"]

  autoSubmit() {
    const inputs = this.element.querySelectorAll("input.score-input")
    const allFilled = Array.from(inputs).every(i => /^\d+$/.test(i.value.trim()))
    if (allFilled) {
      this.formTarget?.requestSubmit()
      this.showIndicator()
    }
  }

  blockInvalid(event) {
    const allowed = ["Backspace", "Delete", "ArrowLeft", "ArrowRight", "Tab"]
    if (allowed.includes(event.key)) return
    if (!/^\d$/.test(event.key)) event.preventDefault()
  }

  clamp(event) {
    const input = event.target
    input.value = input.value.replace(/[^\d]/g, "")
    const val = parseInt(input.value, 10)
    if (!isNaN(val) && val > 99) input.value = "99"
  }

  showIndicator() {
    if (!this.hasIndicatorTarget) return
    this.indicatorTarget.classList.remove("opacity-0")
    this.indicatorTarget.classList.add("opacity-100")
    clearTimeout(this._hideTimer)
    this._hideTimer = setTimeout(() => {
      this.indicatorTarget.classList.remove("opacity-100")
      this.indicatorTarget.classList.add("opacity-0")
    }, 2500)
  }
}
