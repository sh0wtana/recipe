class TagsController < ApplicationController
  before_action :set_tag, only: %i[ edit update destroy ]

  PAGE_LIMIT = 40

  def index
    # Conditions land on the relation Ransack is given, so starting from the
    # association keeps a crafted query inside this user's tags.
    @q = Current.user.tags.ransack(params[:q])

    # Lets the empty state say "nothing matched" rather than "no tags".
    @search_term = params.dig(:q, Tag::SEARCH_PARAM)

    # Eager loaded because every row shows its recipe count, and that count is
    # the only warning before a delete that cannot be undone.
    found = @q.result.includes(:recipes).order(:name)

    @pagy, @tags = pagy(:offset, found, limit: PAGE_LIMIT)
  end

  def new
    @tag = Current.user.tags.build
  end

  def create
    @tag = Current.user.tags.build(tag_params)

    if @tag.save
      redirect_to tags_path, notice: t(".created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @tag.update(tag_params)
      redirect_to tags_path, notice: t(".updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @tag.destroy!
    redirect_to tags_path, notice: t(".destroyed"), status: :see_other
  end

  private
    # There is no authorization layer behind this. Scoping through the
    # association is the only thing keeping tags private.
    def set_tag
      @tag = Current.user.tags.find(params[:id])
    end

    def tag_params
      params.expect(tag: [ :name ])
    end
end
