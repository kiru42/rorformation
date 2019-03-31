class PostsController < ApplicationController

  before_action :set_post, only: [:update, :edit, :show, :destroy]

  def index
    @posts = Post.all
  end

  def show
  end

  def edit
  end

  def update
    post_params = params.require(:post).permit(:name, :content)
    @post.update(post_params)
    redirect_to posts_path
  end

  def new
    @post = Post.new
  end

  def create
    post = Post.create(post_params)
    redirect_to post_path(post.id)
  end

  def destroy
    @post.destroy
    redirect_to posts_path
  end

  private

  def post_params
    params.require(:post).permit(:name, :content)
  end

  def set_post
    @post = Post.find(params[:id])
  end

end
