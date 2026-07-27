import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  start() {
    this.overlayTarget.hidden = false
    document.body.classList.add("overflow-hidden")
    document.body.setAttribute("aria-busy", "true")
  }

  finish() {
    this.overlayTarget.hidden = true
    document.body.classList.remove("overflow-hidden")
    document.body.removeAttribute("aria-busy")
  }
}
