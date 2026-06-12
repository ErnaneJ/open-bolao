import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["day", "btn", "dateRange", "startDate", "endDate", "empty"]

  connect() {
    this.currentFilter = "all"
    this.applyFilter()
  }

  setFilter(event) {
    this.currentFilter = event.currentTarget.dataset.filter
    this.btnTargets.forEach(b => b.classList.toggle("filter-pill-active", b === event.currentTarget))
    this.dateRangeTarget.classList.toggle("hidden", this.currentFilter !== "range")
    this.applyFilter()
  }

  applyFilter() {
    const start = this.startDateTarget.value
    const end = this.endDateTarget.value
    let visible = 0

    this.dayTargets.forEach(day => {
      const show = this.#isVisible(day, start, end)
      day.hidden = !show
      if (show) visible++
    })

    this.emptyTarget.hidden = visible > 0
  }

  #isVisible(day, start, end) {
    switch (this.currentFilter) {
      case "all":      return true
      case "finished": return day.dataset.allFinished === "true"
      case "live":     return day.dataset.hasLive === "true"
      case "range": {
        const d = day.dataset.date
        return !!d && (!start || d >= start) && (!end || d <= end)
      }
    }
  }
}
