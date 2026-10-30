import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "location",
    "npcs",
    "mapLegend",
    "mapCanvas",
    "mapLines"
  ]

  static values = {
    url: String
  }

  connect() {
    this.intervalId = null
    this.requestController = null
    this.currentMap = null

    this.currentLocation = {
      status: this.locationTarget.dataset.locationStatus,
      id: this.locationTarget.dataset.locationId || null,
      name: this.locationTarget.querySelector("h3")?.textContent.trim() || null
    }

    const ids = (this.npcsTarget.dataset.npcIds || "")
      .split(",")
      .filter(Boolean)

    const names = Array.from(
      this.npcsTarget.querySelectorAll("li")
    ).map((item) => item.textContent.trim())

    this.currentNpcs = ids.map((id, index) => ({
      id: Number(id),
      name: names[index]
    }))

    this.visibilityHandler = () => this.handleVisibilityChange()

    document.addEventListener(
      "visibilitychange",
      this.visibilityHandler
    )

    this.startPolling()
  }

  disconnect() {
    document.removeEventListener(
      "visibilitychange",
      this.visibilityHandler
    )

    this.stopPolling()
  }

  startPolling() {
    if (document.hidden || this.intervalId !== null) return

    this.poll()

    this.intervalId = window.setInterval(() => {
      this.poll()
    }, 5000)
  }

  stopPolling() {
    if (this.intervalId !== null) {
      window.clearInterval(this.intervalId)
      this.intervalId = null
    }

    if (this.requestController) {
      this.requestController.abort()
      this.requestController = null
    }
  }

  handleVisibilityChange() {
    if (document.hidden) {
      this.stopPolling()
    } else {
      this.startPolling()
    }
  }

  async poll() {
    if (document.hidden || this.requestController) return

    const controller = new AbortController()
    this.requestController = controller

    try {
      const response = await fetch(this.urlValue, {
        signal: controller.signal,
        headers: {
          Accept: "application/json"
        },
        cache: "no-store"
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`)
      }

      const data = await response.json()

      if (!controller.signal.aborted) {
        this.updateScreen(data)
      }
    } catch (error) {
      if (!controller.signal.aborted) {
        console.warn("セッション情報の取得に失敗しました", error)
      }
    } finally {
      if (this.requestController === controller) {
        this.requestController = null
      }
    }
  }

  updateScreen(data) {
    const location = {
      status: data.location_status,
      id: data.current_location?.id?.toString() || null,
      name: data.current_location?.name || null
    }

    const locationChanged =
      JSON.stringify(location) !== JSON.stringify(this.currentLocation)

    if (locationChanged) {
      this.updateLocation(location)
      this.currentLocation = location
    }

    const npcs = data.appeared_npcs

    if (JSON.stringify(npcs) !== JSON.stringify(this.currentNpcs)) {
      this.updateNpcs(npcs)
      this.currentNpcs = npcs
    }

    const map = {
      locations: data.map_locations,
      connections: data.map_connections
    }

    if (
      Array.isArray(map.locations) &&
      Array.isArray(map.connections)
    ) {
      const mapChanged =
        JSON.stringify(map) !== JSON.stringify(this.currentMap)

      if (mapChanged) {
        this.updateMapContents(map)
        this.currentMap = map
      }

      if (mapChanged || locationChanged) {
        this.updateMap(location.id)
      }
    } else if (locationChanged) {
      this.updateMap(location.id)
    }
  }

  updateLocation(location) {
    const container = this.locationTarget

    if (location.status === "public" && location.name) {
      const card = document.createElement("div")
      card.className = "card"

      const body = document.createElement("div")
      body.className = "card-body"

      const heading = document.createElement("h3")
      heading.className = "h5 mb-0"
      heading.textContent = location.name

      body.append(heading)
      card.append(body)
      container.replaceChildren(card)
    } else {
      const message = document.createElement("div")
      message.className = "alert alert-secondary"

      message.textContent = location.status === "hidden"
        ? "現在地の情報はまだ公開されていません。"
        : "現在地は未設定です。"

      container.replaceChildren(message)
    }

    container.dataset.locationStatus = location.status
    container.dataset.locationId = location.id || ""
  }

  updateMapContents(map) {
    if (!this.hasMapCanvasTarget || !this.hasMapLinesTarget) return

    const canvas = this.mapCanvasTarget
    const lines = this.mapLinesTarget

    const nodes = map.locations.map((location) => {
      return this.buildMapNode(location)
    })

    const connections = map.connections.map((connection) => {
      const source = map.locations.find(
        (location) => location.id === connection.source_location_id
      )

      const destination = map.locations.find(
        (location) => location.id === connection.destination_location_id
      )

      if (!source || !destination) return null

      const line = document.createElementNS(
        "http://www.w3.org/2000/svg",
        "line"
      )

      line.setAttribute("class", "scenario-map-connection")
      line.setAttribute("x1", source.x)
      line.setAttribute("y1", source.y)
      line.setAttribute("x2", destination.x)
      line.setAttribute("y2", destination.y)
      line.setAttribute("vector-effect", "non-scaling-stroke")
      line.dataset.scenarioMapTarget = "connection"
      line.dataset.sourceLocationId = source.id
      line.dataset.destinationLocationId = destination.id

      return line
    }).filter(Boolean)

    lines.replaceChildren(...connections)

    canvas.querySelectorAll(
      ':scope > [data-scenario-map-target="node"]'
    ).forEach((node) => node.remove())

    canvas.append(...nodes)
  }

  buildMapNode(location) {
    const article = document.createElement("article")

    article.className = "scenario-map-location"
    article.dataset.scenarioMapTarget = "node"
    article.dataset.locationId = location.id

    article.style.setProperty("--map-x", `${location.x}%`)
    article.style.setProperty("--map-y", `${location.y}%`)

    const header = document.createElement("div")
    header.className =
      "d-flex justify-content-between align-items-start gap-2 mb-2"

    const number = document.createElement("span")
    number.className = "scenario-map-location-number"
    number.textContent = location.position

    header.append(number)

    const title = document.createElement("h3")
    title.className = "scenario-map-location-name"
    title.textContent = location.name

    const description = document.createElement("p")
    description.className = "scenario-map-location-description"
    description.textContent = location.description

    article.append(header, title, description)

    return article
  }

  updateMap(locationId) {
    const activeIds = locationId ? [locationId] : []

    this.element.querySelectorAll(
      '[data-scenario-map-target="node"]'
    ).forEach((node) => {
      const active = activeIds.includes(node.dataset.locationId)
      node.classList.toggle("is-active", active)
    })

    this.element.querySelectorAll(
      '[data-scenario-map-target="connection"]'
    ).forEach((connection) => {
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

    if (this.hasMapLegendTarget) {
      const hasActiveNode = Array.from(
        this.element.querySelectorAll('[data-scenario-map-target="node"]')
      ).some((node) => node.classList.contains("is-active"))

      this.mapLegendTarget.hidden = !hasActiveNode
    }
  }

  updateNpcs(npcs) {
    const container = this.npcsTarget

    if (npcs.length === 0) {
      const message = document.createElement("div")
      message.className = "alert alert-secondary"
      message.textContent = "まだ登場した人物はいません。"

      container.replaceChildren(message)
    } else {
      const list = document.createElement("ul")
      list.className = "list-group"

      npcs.forEach((npc) => {
        const item = document.createElement("li")
        item.className = "list-group-item"
        item.textContent = npc.name
        list.append(item)
      })

      container.replaceChildren(list)
    }

    container.dataset.npcIds = npcs.map((npc) => npc.id).join(",")
  }
}
