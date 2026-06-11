import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "checkbox", "counter", "bar", "form", "ids"]

  toggleAll() {
    const checked = this.toggleTarget.checked
    this.checkboxTargets.forEach(cb => { cb.checked = checked })
    this.update()
  }

  update() {
    const selected = this.checkboxTargets.filter(cb => cb.checked)
    const total    = this.checkboxTargets.length

    if (this.hasToggleTarget) {
      this.toggleTarget.indeterminate = selected.length > 0 && selected.length < total
      this.toggleTarget.checked       = selected.length === total && total > 0
    }

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = selected.length > 0 ? `${selected.length} selecionado(s)` : ""
    }

    if (this.hasBarTarget) {
      this.barTarget.classList.toggle("hidden", selected.length === 0)
    }
  }

  // Called by the delete button — populates hidden inputs then submits the form
  destroy(event) {
    event.preventDefault()
    const selected = this.checkboxTargets.filter(cb => cb.checked)
    if (selected.length === 0) return

    const confirmMsg = event.currentTarget.dataset.confirm ||
                       `Excluir ${selected.length} item(ns) selecionado(s)?`
    if (!confirm(confirmMsg)) return

    // Populate the hidden ids container
    this.idsTarget.innerHTML = ""
    selected.forEach(cb => {
      const input = document.createElement("input")
      input.type  = "hidden"
      input.name  = "ids[]"
      input.value = cb.value
      this.idsTarget.appendChild(input)
    })

    this.formTarget.submit()
  }
}
