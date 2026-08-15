module RecipesHelper
  # A name the user typed has no Tag row until the recipe saves, so a list built
  # from their tags alone would drop it the moment a save is rejected.
  def tag_choices(recipe)
    (recipe.user.tags.map(&:name) | recipe.tag_names).sort
  end
end
