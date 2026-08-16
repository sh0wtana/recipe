import { Controller } from "@hotwired/stimulus"

// The server cannot show a file that has not been sent yet, so the preview has
// to be drawn here.
export default class extends Controller {
  static targets = ["input", "image", "flag", "button", "label"]

  connect() {
    this.prompt = this.labelTarget.textContent
  }

  show() {
    const [ file ] = this.inputTarget.files
    if (!file) return

    this.flagTarget.value = ""
    this.labelTarget.textContent = this.prompt
    this.display(URL.createObjectURL(file))
  }

  remove() {
    this.inputTarget.value = ""
    this.flagTarget.value = "1"
    this.labelTarget.textContent = this.prompt
    this.display(null)
  }

  // Chrome and Firefox cannot decode HEIF, so a photo picked on a computer
  // draws a broken image. Naming the file still confirms the pick landed.
  // iOS decodes HEIF, so this never fires on the phone this app is used from.
  failed() {
    this.imageTarget.classList.add("hidden")
    this.labelTarget.textContent = this.inputTarget.files[0]?.name ?? this.prompt
  }

  // The hidden class, not the hidden attribute: Tailwind writes [hidden] inside
  // :where(), so it carries no specificity and loses to daisyUI's .btn.
  display(src) {
    URL.revokeObjectURL(this.imageTarget.src)

    // Removing the attribute rather than blanking it — an empty src is itself
    // a load failure, and would call failed() on the way out.
    if (src) {
      this.imageTarget.src = src
    } else {
      this.imageTarget.removeAttribute("src")
    }

    this.imageTarget.classList.toggle("hidden", !src)
    this.buttonTarget.classList.toggle("hidden", !src)
  }
}
