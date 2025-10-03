module Sqema::Ui::Page
  class Component < Sqema::ApplicationViewComponent
    option(:title)
    option(:subtitle, optional: true)
    option(:description, optional: true)

    renders_one(:actions_area)
  end
end
