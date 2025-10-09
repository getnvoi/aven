# Engine's own importmap configuration
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "aven/application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

pin_all_from(
  Aven::Engine.root.join("app/javascript/aven/controllers"),
  under: "aven/controllers",
)

pin_all_from(
  Aven::Engine.root.join("app/components/aven"),
  under: "aven/components",
  to: "aven"
)
