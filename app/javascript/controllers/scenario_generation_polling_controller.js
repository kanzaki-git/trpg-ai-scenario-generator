import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "loading",
    "failure",
    "communicationFailure"
  ]

  static values = {
    statusUrl: String,
    interval: Number
  }

  connect() {
    this.consecutiveFailureCount = 0
    this.checkStatus()
  }

  disconnect() {
    clearTimeout(this.pollingTimer)
  }

  async checkStatus() {
    try {
      const response = await fetch(this.statusUrlValue, {
        headers: {
          Accept: "application/json"
        }
      })

      if (!response.ok) {
        throw new Error(`生成状態の確認に失敗しました: ${response.status}`)
      }

      const data = await response.json()

      this.consecutiveFailureCount = 0

      if (data.status === "completed" && data.redirect_url) {
        window.location.assign(data.redirect_url)
        return
      }

      if (data.status === "failed") {
        this.showFailure()
        return
      }
    } catch (error) {
      console.error(error)
      this.consecutiveFailureCount += 1

      if (this.consecutiveFailureCount >= 3) {
        this.showCommunicationFailure()
        return
      }
    }

    this.pollingTimer = setTimeout(
      () => this.checkStatus(),
      this.intervalValue
    )
  }

  showFailure() {
    this.loadingTarget.classList.add("d-none")
    this.failureTarget.classList.remove("d-none")
  }

  showCommunicationFailure() {
    this.loadingTarget.classList.add("d-none")
    this.communicationFailureTarget.classList.remove("d-none")
  }

  reload() {
    window.location.reload()
  }
}
