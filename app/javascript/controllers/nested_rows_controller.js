import { Controller } from "@hotwired/stimulus"

// Mounted once per fieldset, so ingredients and steps get independent instances.
// Nothing here knows which collection it is driving: a row is whatever carries
// the row target, and the only fields it touches are the two hidden ones every
// row has.
export default class extends Controller {
  static targets = ["list", "row", "template"]

  // A row re-rendered after a failed save can already carry _destroy="true" —
  // Rails marks it for destruction and re-renders it anyway rather than
  // dropping it. Left alone it would renumber like a survivor and look
  // restored, so hide it before the first renumber.
  connect() {
    this.rowTargets
      .filter((row) => this.destroyed(row))
      .forEach((row) => { row.hidden = true })

    this.renumber()
  }

  add() {
    const html = this.templateTarget.innerHTML.replaceAll("NEW_RECORD", this.nextIndex())

    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.renumber()
  }

  // Hidden, not detached. A detached row submits nothing at all, so _destroy
  // never reaches the server and the record survives the save.
  remove(event) {
    const row = this.rowTargets.find((row) => row.contains(event.target))
    if (!row) return

    row.querySelector("[data-destroy]").value = "1"
    row.hidden = true
    this.renumber()
  }

  renumber() {
    this.rowTargets
      .filter((row) => !row.hidden)
      .forEach((row, index) => { row.querySelector("[data-position]").value = index })
  }

  // Rails renders the field as the string "false" when a row is not marked
  // for destruction, and Boolean("false") is true — so this checks the value
  // against the set of true-ish Rails booleans instead of trusting JS truthiness.
  destroyed(row) {
    return [ "1", "true" ].includes(row.querySelector("[data-destroy]").value)
  }

  // Date.now() on its own repeats inside a millisecond, and two rows sharing a
  // child index arrive as a single record.
  nextIndex() {
    this.lastIndex = Math.max(Date.now(), (this.lastIndex ?? 0) + 1)
    return this.lastIndex
  }
}
