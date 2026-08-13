import { Controller } from "@hotwired/stimulus"

// Mounted once per fieldset, so ingredients and steps get independent instances.
// Nothing here knows which collection it is driving: a row is whatever carries
// the row target, and the only fields it touches are the two hidden ones every
// row has.
export default class extends Controller {
  static targets = ["list", "row", "template"]

  // hidden is set from _destroy, never merely added to, because the two
  // survive a Turbo restoration visit differently: hidden reflects to a DOM
  // attribute, which cloneNode(true) preserves in the cached snapshot, while
  // _destroy is a plain input value, which it does not. Deleting a row, then
  // navigating away and back with the browser's Back button, would otherwise
  // serve a snapshot where the row is still hidden but _destroy has reverted
  // to the server-rendered "false" — resurrecting it as invisible-but-alive.
  // A row re-rendered after a failed save can also already carry
  // _destroy="true", since Rails marks it for destruction and re-renders it
  // anyway rather than dropping it.
  connect() {
    this.rowTargets.forEach((row) => { row.hidden = this.destroyed(row) })
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
