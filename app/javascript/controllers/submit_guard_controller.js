import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Only input[type=text]: the submit input and type=button add/remove
  // buttons also activate on Enter, via this same bubbled keydown's default
  // action, and would stop responding to keyboard Enter otherwise.
  guard(event) {
    if (event.key !== "Enter" || event.isComposing) return
    if (event.target.type !== "text") return

    event.preventDefault()
  }
}
