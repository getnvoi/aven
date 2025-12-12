Rails.application.routes.draw do
  root to: proc { [200, {}, ["OK"]] }
  mount Aven::Engine => "/aven"
end
