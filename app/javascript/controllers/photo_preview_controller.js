import { Controller } from "@hotwired/stimulus"

// The server cannot show a file that has not been sent yet, so the preview has
// to be drawn here.
export default class extends Controller {
  static targets = ["input", "image", "flag", "button"]

  show() {
    const [ file ] = this.inputTarget.files
    if (!file) return

    this.flagTarget.value = ""
    this.display(URL.createObjectURL(file))
  }

  remove() {
    this.inputTarget.value = ""
    this.flagTarget.value = "1"
    this.display(null)
  }

  // The hidden class, not the hidden attribute: Tailwind writes [hidden] inside
  // :where(), so it carries no specificity and loses to daisyUI's .btn.
  display(src) {
    URL.revokeObjectURL(this.imageTarget.src)
    this.imageTarget.src = src ?? ""
    this.imageTarget.classList.toggle("hidden", !src)
    this.buttonTarget.classList.toggle("hidden", !src)
  }
}
