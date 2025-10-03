module Sqema::Views::Static::Index
  class Component < Sqema::ApplicationViewComponent
    option(:current_user, optional: true)
  end
end
