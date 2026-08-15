class RecipesController < ApplicationController
  before_action :set_recipe, only: %i[ show edit update destroy ]

  def index
    # Conditions land on the relation Ransack is given, so starting from the
    # association keeps a crafted query inside this user's recipes.
    @q = Current.user.recipes.ransack(params[:q])

    # Lets the empty state say "nothing matched" rather than "no recipes".
    @search_term = params.dig(:q, Recipe::SEARCH_PARAM)

    # distinct: a has_many match returns the recipe once per matching row.
    @recipes = @q.result(distinct: true).includes(:tags).order(created_at: :desc)
  end

  def show
  end

  def new
    @recipe = Current.user.recipes.build
    @recipe.ingredients.build(position: 0)
    @recipe.steps.build(position: 0)
  end

  def create
    @recipe = Current.user.recipes.build(recipe_params)

    if @recipe.save
      redirect_to @recipe, notice: t(".created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to @recipe, notice: t(".updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @recipe.destroy!
    redirect_to recipes_path, notice: t(".destroyed"), status: :see_other
  end

  private
    # There is no authorization layer behind this. Scoping through the
    # association is the only thing keeping recipes private.
    def set_recipe
      @recipe = Current.user.recipes.find(params[:id])
    end

    # The doubly nested arrays are load-bearing: flattening them drops every
    # ingredient and step without raising anything.
    def recipe_params
      params.expect(recipe: [ :title, :description, :servings, :tips,
                              tag_names: [],
                              ingredients_attributes: [ [ :id, :name, :amount, :position, :_destroy ] ],
                              steps_attributes:       [ [ :id, :body, :position, :_destroy ] ] ])
    end
end
