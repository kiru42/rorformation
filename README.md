# DOCUMENTATION

## Docker & Rails

- https://nickjanetakis.com/blog/dockerize-a-rails-5-postgres-redis-sidekiq-action-cable-app-with-docker-compose

```bash
gem install orats
orats new rorformation
```

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
