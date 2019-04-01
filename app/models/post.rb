class Post < ApplicationRecord

  include Sluggable
  
  def as_json(options = nil)
    super(only: [:name, :id, :created_at])
  end
end