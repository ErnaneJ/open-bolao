import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tournamentField", "matchField", "matchSearch", "matchResults", "matchId", "selectedMatch"]

  scopeChanged(event) {
    const scope = event.target.value
    if (this.hasTournamentFieldTarget) this.tournamentFieldTarget.classList.toggle("hidden", scope !== "tournament")
    if (this.hasMatchFieldTarget)      this.matchFieldTarget.classList.toggle("hidden",      scope !== "single_match")
  }

  searchMatches(event) {
    const query = event.target.value.trim()
    if (query.length < 2) {
      this.matchResultsTarget.innerHTML = ""
      return
    }
    clearTimeout(this._searchTimer)
    this._searchTimer = setTimeout(async () => {
      const res = await fetch(`/admin/matches.json?q=${encodeURIComponent(query)}`, {
        headers: { "Accept": "application/json" }
      })
      if (!res.ok) return
      const matches = await res.json()
      this.renderResults(matches)
    }, 300)
  }

  renderResults(matches) {
    if (!matches.length) {
      this.matchResultsTarget.innerHTML = '<p class="text-xs text-pitch-400 p-2">Nenhum jogo encontrado.</p>'
      return
    }
    this.matchResultsTarget.innerHTML = matches.map(m => `
      <button type="button"
              class="w-full text-left px-3 py-2 rounded-lg hover:bg-pitch-50 dark:hover:bg-pitch-700 text-sm transition-colors flex items-center gap-2"
              data-action="click->pool-form#selectMatch"
              data-match-id="${m.id}"
              data-match-label="${m.label}">
        ${m.home_flag ? `<img src="${m.home_flag}" class="w-5 h-3.5 object-cover rounded shrink-0">` : ""}
        <span class="flex-1 truncate">${m.label}</span>
        ${m.away_flag ? `<img src="${m.away_flag}" class="w-5 h-3.5 object-cover rounded shrink-0">` : ""}
        <span class="text-xs text-pitch-400 shrink-0">${m.date || ""}</span>
      </button>
    `).join("")
  }

  selectMatch(event) {
    const btn = event.currentTarget
    this.matchIdTarget.value = btn.dataset.matchId
    this.matchSearchTarget.value = ""
    this.matchResultsTarget.innerHTML = ""
    if (this.hasSelectedMatchTarget) {
      this.selectedMatchTarget.textContent = "✓ " + btn.dataset.matchLabel
      this.selectedMatchTarget.classList.remove("hidden")
    }
  }
}
