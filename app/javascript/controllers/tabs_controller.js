import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const hash = window.location.hash.replace("#", "")
    const matched = this.tabTargets.find(t => `tab-${t.dataset.tab}` === hash)
    this.showTab(matched?.dataset.tab || this.tabTargets[0]?.dataset.tab)
  }

  show(event) {
    const tab = event.currentTarget.dataset.tab
    history.replaceState(null, "", `#tab-${tab}`)
    this.showTab(tab)
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
