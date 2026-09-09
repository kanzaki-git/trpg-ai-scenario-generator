import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const targetId = event.params.targetId
    const destination = document.getElementById(targetId)

    if (!(destination instanceof HTMLDetailsElement)) {
      return
    }

    event.preventDefault()
    destination.open = true

    requestAnimationFrame(() => {
      destination.scrollIntoView({
        behavior: "smooth",
        block: "start"
      })

      window.history.replaceState(
        null,
        "",
        `#${targetId}`
      )
    })
  }
}
