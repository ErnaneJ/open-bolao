// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Custom Turbo Stream action: <turbo-stream action="redirect" target="/path"></turbo-stream>
// Lets frame form submissions trigger a full-page visit on success without "Content Missing".
Turbo.StreamActions.redirect = function () {
  Turbo.visit(this.getAttribute("target"))
}
