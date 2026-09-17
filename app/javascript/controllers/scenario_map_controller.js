import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["node", "connection"]

  static values = {
    activeLocationIds: Array
  }

  connect() {
    this.updateHighlight()
  }

  highlightScene(event) {
    const scene = event.currentTarget

    if (!(scene instanceof HTMLDetailsElement) || !scene.open) {
      return
    }

    const locationIds = JSON.parse(
      scene.dataset.locationIds || "[]"
    )

    this.activeLocationIdsValue = locationIds
  }

  activeLocationIdsValueChanged() {
    this.updateHighlight()
  }

  updateHighlight() {
    const activeIds = this.activeLocationIdsValue.map(String)

    this.nodeTargets.forEach((node) => {
      const active = activeIds.includes(node.dataset.locationId)

      node.classList.toggle("is-active", active)
    })

    this.connectionTargets.forEach((connection) => {
      const sourceActive = activeIds.includes(
        connection.dataset.sourceLocationId
      )
      const destinationActive = activeIds.includes(
        connection.dataset.destinationLocationId
      )

      connection.classList.toggle(
        "is-active",
        sourceActive && destinationActive
      )
    })
  }
}
