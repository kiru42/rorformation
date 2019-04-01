class Post < ApplicationRecord

  validates :name, name: true
  validates :content, name: true
  
  def as_json(options = nil)
    super(only: [:name, :id, :created_at])
  end
end