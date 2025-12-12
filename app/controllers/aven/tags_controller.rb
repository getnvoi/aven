# frozen_string_literal: true

module Aven
  class TagsController < Aven::ApplicationController
    include Aven::Authentication

    before_action :authenticate_user!

    # GET /tags or /tags.json
    # Supports search via ?q= parameter
    def index
      tags = ActsAsTaggableOn::Tag.all

      if params[:q].present?
        tags = tags.where("name ILIKE ?", "%#{params[:q]}%")
      end

      tags = tags.order(:name).limit(params[:limit] || 50)

      respond_to do |format|
        format.html { render plain: tags.pluck(:name).join(", ") }
        format.json { render json: tags.pluck(:name) }
      end
    end

    # POST /tags or /tags.json
    # Creates a new tag
    def create
      tag_name = params.dig(:tag, :name) || params[:name]

      if tag_name.blank?
        render json: { error: "Name is required" }, status: :unprocessable_entity
        return
      end

      tag = ActsAsTaggableOn::Tag.find_or_create_by(name: tag_name.strip)

      respond_to do |format|
        format.html { redirect_to tags_path, notice: "Tag created" }
        format.json { render json: { id: tag.id, name: tag.name }, status: :created }
      end
    end
  end
end
