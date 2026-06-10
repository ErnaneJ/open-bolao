import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    // Show first panel by default
    this.showTab(this.tabTargets[0]?.dataset.tab)
  }

  show(event) {
    this.showTab(event.currentTarget.dataset.tab)
  }

  showTab(tabId) {
    if (!tabId) return

    this.tabTargets.forEach(tab => {
      const active = tab.dataset.tab === tabId
      tab.classList.toggle("border-indigo-600", active)
      tab.classList.toggle("text-indigo-600", active)
      tab.classList.toggle("border-transparent", !active)
      tab.classList.toggle("text-gray-500", !active)
    })

    document.querySelectorAll("[id^='tab-']").forEach(panel => {
      panel.classList.toggle("hidden", panel.id !== `tab-${tabId}`)
    })
  }
}
