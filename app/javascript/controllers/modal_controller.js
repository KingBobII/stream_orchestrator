import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "panel"]

  connect() {
    this.onKeydown = this.onKeydown.bind(this)
    window.addEventListener("keydown", this.onKeydown)
  }

  disconnect() {
    window.removeEventListener("keydown", this.onKeydown)
  }

  open() {
    this.dialogTarget.classList.remove("hidden")
    this.dialogTarget.setAttribute("aria-hidden", "false")
    document.body.classList.add("overflow-hidden")

    requestAnimationFrame(() => {
      this.panelTarget.classList.remove("opacity-0", "scale-95", "translate-y-4")
      this.panelTarget.classList.add("opacity-100", "scale-100", "translate-y-0")
    })

    const firstInput = this.panelTarget.querySelector("input, select, textarea, button")
    if (firstInput) {
      setTimeout(() => firstInput.focus(), 150)
    }
  }

  close() {
    this.panelTarget.classList.add("opacity-0", "scale-95", "translate-y-4")
    this.panelTarget.classList.remove("opacity-100", "scale-100", "translate-y-0")
    this.dialogTarget.setAttribute("aria-hidden", "true")
    document.body.classList.remove("overflow-hidden")

    window.setTimeout(() => {
      this.dialogTarget.classList.add("hidden")
    }, 150)
  }

  onKeydown(event) {
    if (event.key === "Escape" && !this.dialogTarget.classList.contains("hidden")) {
      this.close()
    }
  }
}
