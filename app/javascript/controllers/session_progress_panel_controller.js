
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const url = new URL(window.location.href)

    if (url.searchParams.get("session_progress_open") !== "1") {
      return
    }

    const button = document.querySelector(
      '[data-bs-toggle="offcanvas"][data-bs-target="#session-progress-panel"]'
    )

    if (!button) {
      console.warn("セッション進行ボタンが見つかりません")
      return
    }

    if (!this.element.classList.contains("show")) {
      button.click()
    }

    url.searchParams.delete("session_progress_open")

    window.history.replaceState(
      window.history.state,
      "",
      url.pathname + url.search + url.hash
    )
  }
}
