# Engine's own importmap configuration
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "sqema/application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from(
  Sqema::Engine.root.join("app/javascript/sqema/controllers"),
  under: "sqema/controllers",
)

pin_all_from(
  Sqema::Engine.root.join("app/components/sqema"),
  under: "sqema/components",
  to: "sqema"
)

