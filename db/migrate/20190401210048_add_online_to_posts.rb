class AddOnlineToPosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :online, :boolean, default: false
  end
end
