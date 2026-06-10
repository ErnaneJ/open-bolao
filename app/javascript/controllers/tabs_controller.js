import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.showTab(this.tabTargets[0]?.dataset.tab)
  }

  show(event) {
    this.showTab(event.currentTarget.dataset.tab)
  }

  showTab(tabId) {
    if (!tabId) return

    this.tabTargets.forEach(tab => {
      const active = tab.dataset.tab === tabId
      tab.classList.toggle("tab-btn-active", active)
      tab.classList.toggle("tab-btn", true)
    })

    document.querySelectorAll("[id^='tab-']").forEach(panel => {
      panel.classList.toggle("hidden", panel.id !== `tab-${tabId}`)
    })
  }
}
