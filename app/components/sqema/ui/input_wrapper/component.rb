module Sqema::Ui::InputWrapper
  class Component < ::Sqema::ApplicationViewComponent
    option(:label, optional: true)
    option(:name)
    option(:id, optional: true)
    option(:helper_text, optional: true)
    option(:error_text, optional: true)
    option(:disabled, default: proc { false })
    option(:required, default: proc { false })
    option(:data, default: proc { {} })
  end
end
