class PagesController < ApplicationController
  def salut
    @name = params[:name]
  end
end
