import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// One instance per fieldset, so ingredients and steps renumber independently.
export default class extends Controller {
  static targets = ["list", "row", "template"]

  // A row can arrive already deleted two ways: a failed save re-renders it
  // still flagged, and a Turbo snapshot restores hidden (an attribute) without
  // _destroy (a property). Deriving one from the other covers both.
  connect() {
    this.rowTargets.forEach((row) => { row.hidden = this.destroyed(row) })
    this.renumber()

    // forceFallback: Chrome's native drag and drop cannot be driven by
    // WebDriver, so the default path leaves reordering with no system test at
    // all. The fallback uses pointer events, which is also what touch gets.
    this.sortable = Sortable.create(this.listTarget, {
      handle: "[data-handle]",
      animation: 150,
      forceFallback: true,
      onEnd: () => this.renumber()
    })
  }

  disconnect() {
    this.sortable.destroy()
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
    this.visibleRows()
      .forEach((row, index) => { row.querySelector("[data-position]").value = index })
  }

  // A removed row is only hidden, so it stays in rowTargets. Nothing about
  // the running order may count it.
  visibleRows() {
    return this.rowTargets.filter((row) => !row.hidden)
  }

  // Rails renders an unflagged row as the string "false", and Boolean("false")
  // is true.
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
