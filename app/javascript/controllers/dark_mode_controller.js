import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const html = document.documentElement
    const isDark = html.classList.toggle("dark")
    document.cookie = `dark_mode=${isDark};path=/;max-age=31536000`
  }
}
