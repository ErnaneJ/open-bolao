import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["day", "btn", "empty"]

  connect() {
    this.currentFilter = "upcoming"
    this.applyFilter()
  }

  setFilter(event) {
    this.currentFilter = event.currentTarget.dataset.filter
    this.btnTargets.forEach(b => b.classList.toggle("filter-pill-active", b === event.currentTarget))
    this.applyFilter()
  }

  applyFilter() {
    let visible = 0

    this.dayTargets.forEach(day => {
      const show = this.#isVisible(day)
      day.hidden = !show
      if (show) visible++
    })

    this.emptyTarget.hidden = visible > 0
  }

  #isVisible(day) {
    switch (this.currentFilter) {
      case "upcoming": return day.dataset.allFinished !== "true"
      case "finished": return day.dataset.allFinished === "true"
      case "all":      return true
    }
  }
}
