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

irb(main):002:0> reload!
Reloading...
=> true
irb(main):003:0> Post.new
=> #<Post id: nil, name: nil, content: nil, created_at: nil, updated_at: nil>
irb(main):004:0> post = Post.new
=> #<Post id: nil, name: nil, content: nil, created_at: nil, updated_at: nil>
irb(main):005:0> post = "Introduction"
=> "Introduction"
irb(main):006:0> post = Post.new
=> #<Post id: nil, name: nil, content: nil, created_at: nil, updated_at: nil>
irb(main):007:0> post.name = "Introduction"
=> "Introduction"
irb(main):008:0> post.content = "Bienvenue sur ce super site"
=> "Bienvenue sur ce super site"
irb(main):009:0>
```
