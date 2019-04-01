class Post < ApplicationRecord

  include Sluggable
  belongs_to :category

  def as_json(options = nil)
    super(only: [:name, :id, :created_at])
  end
end