# frozen_string_literal: true

module Aven
  module Agentic
    class DocumentsController < Aven::ApplicationController
      before_action :authenticate_user!
      before_action :set_document, only: [:show, :destroy]

      def index
        @documents = current_workspace.aven_agentic_documents.recent
        render json: @documents
      end

      def show
        render json: @document
      end

      def create
        @document = current_workspace.aven_agentic_documents.build(document_params)

        if params[:file].present?
          @document.file.attach(params[:file])
          @document.filename = params[:file].original_filename
          @document.content_type = params[:file].content_type
          @document.byte_size = params[:file].size
        end

        if @document.save
          render json: @document, status: :created
        else
          render json: { errors: @document.errors }, status: :unprocessable_entity
        end
      end

      def destroy
        @document.destroy
        head :no_content
      end

      private

        def set_document
          @document = current_workspace.aven_agentic_documents.find(params[:id])
        end

        def document_params
          params.permit(:filename)
        end
    end
  end
end
