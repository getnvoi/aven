import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["output"];

  connect() {
    console.log("xx");
    console.log(this.outputTarget);
  }

  greet() {
    this.outputTarget.textContent = "Hello from Nvoi Engine!";
  }
}
