module Aven::Views::Static::Index
  class Component < Aven::ApplicationViewComponent
    option(:current_user, optional: true)
  end
end
