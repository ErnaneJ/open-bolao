import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "submitBtn"]

  // Auto-submit when both score fields are filled
  autoSubmit() {
    const inputs = this.element.querySelectorAll("input[type='number']")
    const allFilled = Array.from(inputs).every(i => i.value !== "")
    if (allFilled) {
      this.formTarget?.requestSubmit()
    }
  }
}
