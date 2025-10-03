module Sqema::Ui::InputPassword
  class Component < Sqema::Ui::FormBuilder::BaseComponent
    option(:autocomplete, default: proc { "current-password" })
    option(:show_toggle, default: proc { true })
  end
end
