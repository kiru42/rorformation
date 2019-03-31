class CategoriesController < ApplicationController

  before_action :set_category, only: [:edit, :update, :update, :show]

  def index
    @categories = Category.all
  end

  def show
  end

  def update
    @category.update(category_params)
    redirect_to category_path(@category.id)
  end

  def destroy
    @category.destroy
    redirect_to categories_path
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.create(category_params)
    redirect_to category_path(@category.id)
  end

  def edit
  end

  private
  def category_params
    params.require(:category).permit(:name, :slug)
  end

  def category
    @category = Category.find(params[:id])
  end

end
