import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "dot"]
  static values = { interval: { type: Number, default: 4000 }, current: { type: Number, default: 0 } }

  connect() {
    if (this.slideTargets.length > 1) {
      this._start()
    }
  }

  disconnect() {
    this._stop()
  }

  next() {
    this.currentValue = (this.currentValue + 1) % this.slideTargets.length
  }

  prev() {
    this.currentValue = (this.currentValue - 1 + this.slideTargets.length) % this.slideTargets.length
  }

  goTo(event) {
    this.currentValue = parseInt(event.currentTarget.dataset.index)
  }

  currentValueChanged() {
    this.slideTargets.forEach((slide, i) => {
      slide.classList.toggle("hidden", i !== this.currentValue)
    })
    this.dotTargets.forEach((dot, i) => {
      dot.classList.toggle("bg-neon-400", i === this.currentValue)
      dot.classList.toggle("bg-pitch-300", i !== this.currentValue)
      dot.classList.toggle("dark:bg-pitch-600", i !== this.currentValue)
    })
  }

  _start() {
    this._stop()
    this._timer = setInterval(() => this.next(), this.intervalValue)
  }

  _stop() {
    clearInterval(this._timer)
  }
}
