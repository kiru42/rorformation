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
