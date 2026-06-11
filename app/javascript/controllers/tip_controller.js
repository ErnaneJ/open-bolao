import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "indicator"]

  // Fire on change (fires after blur if value changed)
  autoSubmit() {
    const inputs = this.element.querySelectorAll("input[type='number']")
    const allFilled = Array.from(inputs).every(i => i.value !== "")
    if (allFilled) {
      this.formTarget?.requestSubmit()
      this.showIndicator()
    }
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
