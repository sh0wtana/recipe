import { Controller } from "@hotwired/stimulus"

// Mounted once per fieldset, so ingredients and steps get independent instances.
// Nothing here knows which collection it is driving: a row is a child of the
// list, and the only fields it touches are the two hidden ones every row has.
export default class extends Controller {
  static targets = ["list", "template"]

  connect() {
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
    const row = this.rows.find((row) => row.contains(event.target))

    row.querySelector("[data-destroy]").value = "1"
    row.hidden = true
    this.renumber()
  }

  renumber() {
    this.rows
      .filter((row) => !row.hidden)
      .forEach((row, index) => { row.querySelector("[data-position]").value = index })
  }

  // Nothing but rows may be placed directly inside the list element.
  get rows() {
    return [...this.listTarget.children]
  }

  // Date.now() on its own repeats inside a millisecond, and two rows sharing a
  // child index arrive as a single record.
  nextIndex() {
    this.lastIndex = Math.max(Date.now(), (this.lastIndex ?? 0) + 1)
    return this.lastIndex
  }
}
