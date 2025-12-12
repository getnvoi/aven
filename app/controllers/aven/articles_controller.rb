# frozen_string_literal: true

module Aven
  class ArticlesController < Aven::ApplicationController
    include Aven::Authentication

    before_action :authenticate_user!
    before_action :set_article, only: [:show, :edit, :update, :destroy]

    # GET /articles
    def index
      @articles = current_workspace.aven_articles.recent

      respond_to do |format|
        format.html { view_component("articles/index", articles: @articles, current_user:) }
        format.json { render json: @articles }
      end
    end

    # GET /articles/:id
    def show
      respond_to do |format|
        format.html { view_component("articles/show", article: @article, current_user:) }
        format.json { render json: @article }
      end
    end

    # GET /articles/new
    def new
      @article = current_workspace.aven_articles.build

      respond_to do |format|
        format.html { view_component("articles/new", article: @article, current_user:) }
        format.json { render json: @article }
      end
    end

    # GET /articles/:id/edit
    def edit
      respond_to do |format|
        format.html { view_component("articles/edit", article: @article, current_user:) }
        format.json { render json: @article }
      end
    end

    # POST /articles
    def create
      @article = current_workspace.aven_articles.build(article_params)
      @article.author = current_user

      if @article.save
        respond_to do |format|
          format.html { redirect_to article_path(@article), notice: "Article was successfully created." }
          format.json { render json: @article, status: :created }
        end
      else
        respond_to do |format|
          format.html do
            response.status = :unprocessable_entity
            view_component("articles/new", article: @article, current_user:)
          end
          format.json { render json: { errors: @article.errors }, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /articles/:id
    def update
      if @article.update(article_params)
        respond_to do |format|
          format.html { redirect_to article_path(@article), notice: "Article was successfully updated." }
          format.json { render json: @article }
        end
      else
        respond_to do |format|
          format.html do
            response.status = :unprocessable_entity
            view_component("articles/edit", article: @article, current_user:)
          end
          format.json { render json: { errors: @article.errors }, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /articles/:id
    def destroy
      @article.destroy

      respond_to do |format|
        format.html { redirect_to articles_path, notice: "Article was successfully deleted." }
        format.json { head :no_content }
      end
    end

    private

      def set_article
        @article = current_workspace.aven_articles.friendly.find(params[:id])
      end

      def article_params
        params.require(:article).permit(
          :title,
          :intro,
          :description,
          :published_at,
          :main_visual,
          tag_list: [],
          article_attachments_attributes: [:id, :file, :position, :_destroy],
          article_relationships_attributes: [:id, :related_article_id, :position, :_destroy]
        )
      end
  end
end
