import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "feedback"]

  async copy() {
    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.showFeedback("共有URLをコピーしました。", "text-success")
    } catch {
      this.sourceTarget.focus()
      this.sourceTarget.select()

      this.showFeedback(
        "自動でコピーできませんでした。URLを選択してコピーしてください。",
        "text-danger"
      )
    }
  }

  showFeedback(message, colorClass) {
    this.feedbackTarget.textContent = message
    this.feedbackTarget.classList.remove(
      "d-none",
      "text-success",
      "text-danger"
    )
    this.feedbackTarget.classList.add(colorClass)
  }
}
