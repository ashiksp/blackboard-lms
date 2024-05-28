# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.3.0
FROM ruby:$RUBY_VERSION-bookworm as base

# Rails app lives here
WORKDIR /deploy

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    BLACKBOARD_DATABASE="blackboard_development" \
    BLACKBOARD_DATABASE_USERNAME="postgres" \
    BLACKBOARD_DATABASE_PASSWORD="" \
    BLACKBOARD_DATABASE_HOST="host.docker.internal" \
    BLACKBOARD_DATABASE_PORT="54320" \
    RAILS_MASTER_KEY=""


# Build stage
FROM base as build

# Install packages required
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential npm libpq-dev libvips pkg-config

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install
RUN rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git
RUN bundle exec bootsnap precompile --gemfile

# Install npm dependencies
COPY package.json package-lock.json ./
RUN npm install
# Copy application code
COPY . .
#
# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/
# Precompile assets for production without the secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
# Final stage
FROM base
### Install packages needed for runtime
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

### Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /deploy /deploy
#
# Run and own only the runtime files as a non-root user for security
RUN useradd deploy --create-home --shell /bin/bash && \
    chown -R deploy:deploy db log storage tmp
USER deploy:deploy

## Entrypoint prepares the database.
ENTRYPOINT ["/deploy/bin/docker-entrypoint"]
# Start the server by default
EXPOSE 3000
CMD ["./bin/rails", "server"]
