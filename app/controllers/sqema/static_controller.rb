module Sqema
  class StaticController < ApplicationController
    

    def index
      view_component("static/index", current_user:)
    end
  end
end
