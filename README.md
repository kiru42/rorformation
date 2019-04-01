# DOCUMENTATION

## Documentation Rails

- https://guides.rubyonrails.org
- https://api.rubyonrails.org
- https://stackoverflow.com/questions/tagged/ruby-on-rails
- https://github.com/rails/rails
- https://weblog.rubyonrails.org/
- https://guides.rubyonrails.org/active_record_migrations.html
- https://guides.rubyonrails.org/active_record_basics.html
- https://guides.rubyonrails.org/active_record_validations.html

## Docker & Rails

- https://nickjanetakis.com/blog/dockerize-a-rails-5-postgres-redis-sidekiq-action-cable-app-with-docker-compose

### Installation & init

```bash
gem install orats
orats new rorformation
```

### Dockerfile

```dockerfile
FROM ruby:2.5-alpine

RUN apk update && apk add build-base nodejs postgresql-dev

RUN mkdir /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --binstubs

COPY . .

LABEL maintainer="Kiruban PREMKUMAR <kiru42@gmail.com>"

CMD puma -C config/puma.rb
```

### docker-compose.yml

```yml
version: '2'

services:
  postgres:
    image: 'postgres:10.3-alpine'
    volumes:
      - 'postgres:/var/lib/postgresql/data'
    env_file:
      - '.env'

  redis:
    image: 'redis:4.0-alpine'
    command: redis-server --requirepass labiloute
    volumes:
      - 'redis:/data'

  website:
    depends_on:
      - 'postgres'
      - 'redis'
    build: .
    ports:
      - '3000:3000'
    volumes:
      - '.:/app'
    env_file:
      - '.env'

  sidekiq:
    depends_on:
      - 'postgres'
      - 'redis'
    build: .
    command: sidekiq -C config/sidekiq.yml.erb
    volumes:
      - '.:/app'
    env_file:
      - '.env'

  cable:
    depends_on:
      - 'redis'
    build: .
    command: puma -p 28080 cable/config.ru
    ports:
      - '28080:28080'
    volumes:
      - '.:/app'
    env_file:
      - '.env'

volumes:
  redis:
  postgres:
```

### Dealing with docker-compose

```bash
# Run everything
docker-compose up --build

# Check the images
docker images

# List running containers
docker-compose ps

# Interacting With the Rails Application
docker-compose exec website rails db:reset
docker-compose exec website rails db:migrate

# Properly stop
docker-compose stop

# delete default controller
docker-compose exec website rails d controller Pages
```

### Errors

- I had an error : `Rack::Timeout::RequestTimeoutException in PagesController#home`

```bash
# fixed by adding
echo "REQUEST_TIMEOUT=30" > .env

# then
docker-compose stop
docker-compose up --build
```

- I've then updated `RACK_TIMEOUT_SERVICE_TIMEOUT=30` and removed `REQUEST_TIMEOUT=30`.

### Dealing with database

```bash
docker-compose exec postgres bash

# in the container
su postgres
psql

# now you are connected to the db
> \l
> \c rorformation_development
> \dt
```

### Generate Migrations

```bash
# create the migration
docker-compose exec website rails generate migration CreatePosts title:string content:text

# run db migration
docker-compose exec website rails db:migrate

# rollback migration
docker-compose exec website rails db:rollback

# create an updating migration
docker-compose exec website rails generate migration RenamePostTitleToName
docker-compose exec website rails db:migrate
```

```ruby
class CreatePostsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :posts do |t|
      t.string :title
      t.text :content
    end
  end
end
```

```ruby
class RenamePostTitleToName < ActiveRecord::Migration[5.2]
  def change
    change_table :posts do |t|
      t.rename :title, :name
      t.timestamps
    end
  end
end
```

- https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-add_column

### Models

```ruby
class Post < ApplicationRecord

end
```

```bash
# running console
docker-compose exec website rails c

# Rails console

# Reloading models etc...

irb(main):002:0> reload!
Reloading...
=> true

# Creating a post
irb(main):006:0> post = Post.new
=> #<Post id: nil, name: nil, content: nil, created_at: nil, updated_at: nil>
irb(main):007:0> post.name = "Introduction"
=> "Introduction"
irb(main):008:0> post.content = "Bienvenue sur ce super site"
=> "Bienvenue sur ce super site"
irb(main):009:0> post.save
   (0.7ms)  BEGIN
  Post Create (1.8ms)  INSERT INTO "posts" ("name", "content", "created_at", "updated_at") VALUES ($1, $2, $3, $4) RETURNING "id"  [["name", "Introduction"], ["content", "Bienvenue sur ce super site"], ["created_at", "2019-03-30 00:31:00.541605"], ["updated_at", "2019-03-30 00:31:00.541605"]]
   (1.6ms)  COMMIT
=> true

# Find a post
irb(main):011:0> Post.find(1)
  Post Load (1.5ms)  SELECT  "posts".* FROM "posts" WHERE "posts"."id" = $1 LIMIT $2  [["id", 1], ["LIMIT", 1]]
=> #<Post id: 1, name: "Introduction", content: "Bienvenue sur ce super site", created_at: "2019-03-30 00:31:00", updated_at: "2019-03-30 00:31:00">
irb(main):012:0> Post.last
  Post Load (0.7ms)  SELECT  "posts".* FROM "posts" ORDER BY "posts"."id" DESC LIMIT $1  [["LIMIT", 1]]
=> #<Post id: 1, name: "Introduction", content: "Bienvenue sur ce super site", created_at: "2019-03-30 00:31:00", updated_at: "2019-03-30 00:31:00">

# another way of creating a post
irb(main):015:0> p = Post.create(name: 'Aurevoir', content: "Ceci n'est qu'un aurevoir...")
   (0.9ms)  BEGIN
  Post Create (1.4ms)  INSERT INTO "posts" ("name", "content", "created_at", "updated_at") VALUES ($1, $2, $3, $4) RETURNING "id"  [["name", "Aurevoir"], ["content", "Ceci n'est qu'un aurevoir..."], ["created_at", "2019-03-30 00:34:43.230171"], ["updated_at", "2019-03-30 00:34:43.230171"]]
   (2.6ms)  COMMIT
=> #<Post id: 2, name: "Aurevoir", content: "Ceci n'est qu'un aurevoir...", created_at: "2019-03-30 00:34:43", updated_at: "2019-03-30 00:34:43">
irb(main):016:0> p.id
=> 2

# Updating a post
irb(main):017:0> p
=> #<Post id: 2, name: "Aurevoir", content: "Ceci n'est qu'un aurevoir...", created_at: "2019-03-30 00:34:43", updated_at: "2019-03-30 00:34:43">
irb(main):018:0> p.update(name: "Au revoir")
   (0.5ms)  BEGIN
  Post Update (1.0ms)  UPDATE "posts" SET "name" = $1, "updated_at" = $2 WHERE "posts"."id" = $3  [["name", "Au revoir"], ["updated_at", "2019-03-30 00:36:30.386805"], ["id", 2]]
   (2.6ms)  COMMIT
=> true
irb(main):019:0> p
=> #<Post id: 2, name: "Au revoir", content: "Ceci n'est qu'un aurevoir...", created_at: "2019-03-30 00:34:43", updated_at: "2019-03-30 00:36:30">
```

### Dealing with controllers

```bash
# creating a controller & action
docker-compose exec website rails g controller Posts index
```

```ruby
Rails.application.routes.draw do
  # ...
  get '/articles', to: 'posts#index', as: 'posts'
end
```

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all
  end
end
```

```erb
<h1 class="text-center">Articles</h1>

<hr />

<% @posts.each do |post| %>
<h2><%= post.name %></h2>
<p>
<%= post.content %>
</p>
<% end %>
```

### Adding Categories

```bash
# rails migration
docker-compose exec website rails g migration CreateCategories name:string slug:string
docker-compose exec website rails db:migrate
```

```ruby
class CreateCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :slug
    end
  end
end
```

```bash
# rails generate model
# we should skip migration with --skip
docker-compose exec website rails g model Category --skip

# creating controller with actions
docker-compose exec website rails g controller Categories index show update destroy new edit
```

### Scaffold

```bash
docker-compose exec website rails g scaffold User username:string bio:text
docker-compose exec website rails db:migrate

# rollback scaffold
docker-compose exec website rails db:rollback
docker-compose exec website rails destroy scaffold User
```

### Dealing with controller filters

```ruby

# filters using syntactic sugar
before_action :set_post, only: [:update, :edit, :show, :destroy]
after_action :notification, only: [:update, :edit]
around_action :around

skip_before_action :verify_authenticity_toke, only: [:edit]

# example of private method
def set_post
  @post = Post.find(params[:id])
end

# around action
def around
  puts "aaa"
  yield
  puts "zzz"
end

# filters as blocks
before_action do |controller|
  puts "Je suis avant l'action"
end

after_action do |controller|
  puts "Je suis après l'action"
end

around_action do |controller|
  puts "Je suis avant l'action"
  yield
  puts "Je suis après l'action"
end
```

### Dealing with sessions

```ruby
# session
session[:user_id] = {username: "Kiruban", id: "12"}
session[:success] = "Mise à jour effectuée."
```

```ruby
# flash notice
flash[:notice] = "Article modifié avec succès"

# or in a redirect
redirect_to posts_path, flash: {success: "Article modifié avec succès"}

# shortcut, by default only alert & notice
redirect_to posts_path, notice: "Article modifié avec succès"

# we can add more with
add_flash_types :warning, :danger, :error
redirect_to posts_path, warning: "Article modifié avec succès"
```

```erb
<% flash.each do |key, msg| %>
  <% unless key == :timedout %>
    <%= content_tag :div, class: "alert alert-dismissable alert-#{key}" do -%>
      <button type="button" class="close" data-dismiss="alert" aria-hidden="true">
        &times;
      </button>
      <%= msg %>
    <% end %>
  <% end %>
<% end %>
```

```ruby
# cookies
cookies[:username] = {
  value: "OK",
  expires: 1.month.from_now
}

cookies[:username] = {
  value: JSON.generate({name: "Kiruban", email: "kk@gmail.com"}),
  expires: 1.month.from_now
}

puts JSON.parse(cookies[:username]).inpect

cookies.signed[:username] = "Kiruban"

cookies.permanent.signed[:username] = "Kiruban"

cookies.encrypted[:code_carte_bleue] = "1234"

cookies.delete(:username)
```

- https://api.rubyonrails.org/v5.1.6.2/classes/ActionDispatch/Cookies.html
- https://guides.rubyonrails.org/action_controller_overview.html#session

### Controllers, gérer plusieurs formats

```ruby
respond_to do |format|
  format.html
  format.json { render json: @posts}
  format.xml { render xml: @posts}
end
```

```ruby
# custom json render in controller
respond_to do |format|
  format.json { render json: @posts.as_json(only: [:name, :created_at, :id])}
end
```

```ruby
# or custom json render in model
class Post < ApplicationRecord
  def as_json(options = nil)
    super(only: [:name, :id, :created_at])
  end
end
```

- https://github.com/rails/jbuilder

### Validations

```ruby
class Post < ApplicationRecord
  validates :name, presence: true
  validates :name, presence: { message: 'ne dois pas être vide' }
  validates :name, length: { is: 3..20 }

  validates :name, format: { with: /\A[a-zA-Z]+\z/}
  validates :name, uniqueness: true
  validates :name, confirmation: true
  validates :name, length: { is: 2 }, on: :create
  validates :name, length: { is: 2 }, allow_blank: true
  validates :name, length: { is: 2 }, allow_nil: true
  validates :name, length: { is: 2 }, strict: true
  validates :name, length: { is: 2 }, if: :check_content_2
  validates :name, length: { is: 2 }, unless: :check_content_2
  validates :name, length: { is: 2 }, unless: Proc.new { |record| record.content.length == 2 }


  def check_content_2
    content.length == 2
  end

end
```

- https://github.com/balexand/email_validato

```ruby
# gem 'email_validator'
# bundle install
validates :my_email_attribute, email: true
```

```ruby
# custom validate
validate :my_custom_validation

def my_custom_validation
  if name.length != 2
    errors.add(:name, 'Le champs doit être de 2 caractères')
    # OR / :not_2 permet de mieux traiter programatiquement
    errors.add(:name, :not_2, { message: 'Le champs doit être de 2 caractères' })
  end
end
```

```ruby
# in model

validates_with NameValidator

# custom validator : models/validators/name_validator.rb
class NameValidator < ActiveModel::Validator
  def validate(record)
    if record.name.nil? || record.name.length != 2
      record.errors.add(:name, :not_2, { message: 'Le champs doit être de 2 caractères'})
    end
    if record.content.nil? || record.content.length != 2
      record.errors.add(:content, 'Le champs doit être de 2 caractères')
    end   
  end
end

# in config/application.rb

   config.autoload_paths << "#{Rails.root}/app/models/validators"
```

```ruby
# Another way with EachValidator
# in model

  validates :name, name: { message: "bloop error"}
  validates :content, name: true

# custom validator : models/validators/name_validator.rb
class NameValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.nil? || value.length != 2
      message = options[:message] || 'doit avoir 2 caractères'
      record.errors.add(attribute, message)
    end
  end
end

# in config/application.rb

   config.autoload_paths << "#{Rails.root}/app/models/validators"
```

* https://guides.rubyonrails.org/active_record_validations.html

### Dealing with callbacks

```bash
docker-compose exec website rails g migration add_slug_to_posts slug:string
docker-compose exec website rails db:migrate
```

```ruby
  before_validation :set_slug, only: :create
  validates :slug, format: { with: /\A[a-z0-9\-]+\z/ }, uniqueness: true

  def set_slug
    # return false if self.name.empty? # doesn't work after rails 4
    # throw :abort  # see api doc
    if !self.name.nil? && !self.name.empty? && ( self.slug.nil? || self.slug.empty?)
      self.slug = name.parameterize
    end
  end
```

* https://guides.rubyonrails.org/active_record_callbacks.html

```ruby
# Custom concerns
# in app/models/concerns/sluggable.rb
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :set_default_slug, on: [:create, :update], if: -> { !slug.nil? }
    validates :slug, format: { with: /\A[a-z0-9\-]+\z/ }, uniqueness: true

    private

    def set_default_slug
      if !self.name.nil? && !self.name.empty? && self.slug.empty?
        self.slug = name.parameterize
      end
    end
  end
end
```

```ruby
# Custom concerns
# in model
class Post < ApplicationRecord
  include Sluggable
end
```